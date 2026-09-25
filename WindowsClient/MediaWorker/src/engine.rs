use crate::devices;
use cpal::traits::{DeviceTrait, StreamTrait};
use cpal::{Sample, SampleFormat, Stream, StreamConfig};
use std::collections::VecDeque;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

pub const FRAME_MS: u32 = 20;
pub const JITTER_FRAMES: usize = 3;

pub struct Loopback {
    _input: Stream,
    _output: Stream,
    controls: Arc<Controls>,
}

struct Controls {
    mute: AtomicBool,
    deaf: AtomicBool,
}

struct Queue {
    pending: VecDeque<Vec<f32>>,
    free: Vec<Vec<f32>>,
    frame: usize,
}

impl Queue {
    fn new(frame: usize) -> Self {
        let mut free = Vec::with_capacity(JITTER_FRAMES + 1);
        for _ in 0..JITTER_FRAMES + 1 {
            free.push(vec![0.0; frame]);
        }
        Self {
            pending: VecDeque::with_capacity(JITTER_FRAMES),
            free,
            frame,
        }
    }

    fn push_drop_old(&mut self, data: &[f32]) {
        if data.len() < self.frame {
            return;
        }
        let mut slot = self.free.pop().unwrap_or_else(|| vec![0.0; self.frame]);
        if slot.len() != self.frame {
            slot.resize(self.frame, 0.0);
        }
        slot.copy_from_slice(&data[..self.frame]);
        if self.pending.len() >= JITTER_FRAMES
            && let Some(old) = self.pending.pop_front()
        {
            self.free.push(old);
        }
        self.pending.push_back(slot);
    }

    fn pop(&mut self, out: &mut [f32]) -> bool {
        let Some(slot) = self.pending.pop_front() else {
            return false;
        };
        let n = self.frame.min(out.len()).min(slot.len());
        out[..n].copy_from_slice(&slot[..n]);
        if n < out.len() {
            out[n..].fill(0.0);
        }
        self.free.push(slot);
        true
    }
}

pub fn start(
    input_id: Option<&str>,
    output_id: Option<&str>,
    channels: u16,
    mute: bool,
    deaf: bool,
) -> Result<Loopback, String> {
    let host = cpal::default_host();
    let input = devices::input(&host, input_id)?;
    let output = devices::output(&host, output_id)?;
    let in_cfg = input
        .default_input_config()
        .map_err(|err| err.to_string())?;
    let out_cfg = output
        .default_output_config()
        .map_err(|err| err.to_string())?;
    let in_rate = in_cfg.sample_rate().0.max(1);
    let in_ch = (channels as u32).clamp(1, in_cfg.channels() as u32) as u16;
    let out_ch = (channels as u32).clamp(1, out_cfg.channels() as u32) as u16;
    let frame = ((in_rate as u64 * FRAME_MS as u64) / 1000).max(1) as usize * in_ch as usize;
    let queue = Arc::new(Mutex::new(Queue::new(frame)));
    let controls = Arc::new(Controls {
        mute: AtomicBool::new(mute),
        deaf: AtomicBool::new(deaf),
    });
    let in_stream = StreamConfig {
        channels: in_ch,
        sample_rate: in_cfg.sample_rate(),
        buffer_size: cpal::BufferSize::Default,
    };
    let mut out_stream = StreamConfig {
        channels: out_ch,
        sample_rate: in_cfg.sample_rate(),
        buffer_size: cpal::BufferSize::Default,
    };
    if output
        .supported_output_configs()
        .map_err(|err| err.to_string())?
        .all(|range| range.max_sample_rate() < in_cfg.sample_rate() || range.min_sample_rate() > in_cfg.sample_rate())
    {
        out_stream.sample_rate = out_cfg.sample_rate();
    }
    let capture = build_input(
        &input,
        &in_stream,
        in_cfg.sample_format(),
        frame,
        in_ch,
        Arc::clone(&queue),
        Arc::clone(&controls),
    )?;
    let playback = build_output(
        &output,
        &out_stream,
        out_cfg.sample_format(),
        OutputWiring {
            frame,
            in_ch,
            out_ch,
            queue,
            controls: Arc::clone(&controls),
        },
    )?;
    capture.play().map_err(|err| err.to_string())?;
    playback.play().map_err(|err| err.to_string())?;
    Ok(Loopback {
        _input: capture,
        _output: playback,
        controls,
    })
}

impl Loopback {
    pub fn set_mute(&self, mute: bool) {
        self.controls.mute.store(mute, Ordering::Relaxed);
    }

    pub fn set_deaf(&self, deaf: bool) {
        self.controls.deaf.store(deaf, Ordering::Relaxed);
    }
}

fn build_input(
    device: &cpal::Device,
    config: &StreamConfig,
    format: SampleFormat,
    frame: usize,
    channels: u16,
    queue: Arc<Mutex<Queue>>,
    controls: Arc<Controls>,
) -> Result<Stream, String> {
    let err = |err| eprintln!("input: {err}");
    match format {
        SampleFormat::F32 => input_stream::<f32>(device, config, frame, channels, queue, controls, err),
        SampleFormat::I16 => input_stream::<i16>(device, config, frame, channels, queue, controls, err),
        SampleFormat::U16 => input_stream::<u16>(device, config, frame, channels, queue, controls, err),
        _ => Err("unsupported_input_format".into()),
    }
}

struct OutputWiring {
    frame: usize,
    in_ch: u16,
    out_ch: u16,
    queue: Arc<Mutex<Queue>>,
    controls: Arc<Controls>,
}

fn build_output(
    device: &cpal::Device,
    config: &StreamConfig,
    format: SampleFormat,
    wiring: OutputWiring,
) -> Result<Stream, String> {
    let err = |err| eprintln!("output: {err}");
    match format {
        SampleFormat::F32 => output_stream::<f32>(device, config, wiring, err),
        SampleFormat::I16 => output_stream::<i16>(device, config, wiring, err),
        SampleFormat::U16 => output_stream::<u16>(device, config, wiring, err),
        _ => Err("unsupported_output_format".into()),
    }
}

fn input_stream<T>(
    device: &cpal::Device,
    config: &StreamConfig,
    frame: usize,
    channels: u16,
    queue: Arc<Mutex<Queue>>,
    controls: Arc<Controls>,
    err: impl FnMut(cpal::StreamError) + Send + 'static,
) -> Result<Stream, String>
where
    T: Sample + cpal::SizedSample + Send + 'static,
    f32: cpal::FromSample<T>,
{
    let mut staging = vec![0.0f32; frame];
    let mut filled = 0usize;
    let ch = channels.max(1) as usize;
    device
        .build_input_stream(
            config,
            move |data: &[T], _| {
                if controls.mute.load(Ordering::Relaxed) {
                    return;
                }
                for sample in data.chunks(ch) {
                    let mut mix = 0.0;
                    for v in sample {
                        mix += (*v).to_sample::<f32>();
                    }
                    mix /= sample.len().max(1) as f32;
                    if ch == 1 {
                        staging[filled] = mix;
                        filled += 1;
                    } else {
                        let left = sample.first().map(|v| (*v).to_sample::<f32>()).unwrap_or(mix);
                        let right = sample.get(1).map(|v| (*v).to_sample::<f32>()).unwrap_or(left);
                        staging[filled] = left;
                        staging[filled + 1] = right;
                        filled += 2;
                    }
                    if filled >= frame {
                        if let Ok(mut q) = queue.try_lock() {
                            q.push_drop_old(&staging);
                        }
                        filled = 0;
                    }
                }
            },
            err,
            None,
        )
        .map_err(|err| err.to_string())
}

fn output_stream<T>(
    device: &cpal::Device,
    config: &StreamConfig,
    wiring: OutputWiring,
    err: impl FnMut(cpal::StreamError) + Send + 'static,
) -> Result<Stream, String>
where
    T: Sample + cpal::SizedSample + Send + 'static,
    T: cpal::FromSample<f32>,
{
    let frame = wiring.frame;
    let mut frame_buf = vec![0.0f32; frame];
    let mut offset = frame;
    let in_ch = wiring.in_ch.max(1) as usize;
    let out_ch = wiring.out_ch.max(1) as usize;
    let queue = wiring.queue;
    let controls = wiring.controls;
    device
        .build_output_stream(
            config,
            move |data: &mut [T], _| {
                let silent = controls.deaf.load(Ordering::Relaxed);
                for sample in data.chunks_mut(out_ch) {
                    if offset >= frame {
                        frame_buf.fill(0.0);
                        if !silent
                            && let Ok(mut q) = queue.try_lock()
                        {
                            let _ = q.pop(&mut frame_buf);
                        }
                        offset = 0;
                    }
                    if in_ch == 1 {
                        let v = T::from_sample(frame_buf[offset]);
                        for dst in sample.iter_mut() {
                            *dst = v;
                        }
                        offset += 1;
                    } else {
                        for (i, dst) in sample.iter_mut().enumerate() {
                            *dst = T::from_sample(frame_buf[offset + i.min(in_ch - 1)]);
                        }
                        offset += in_ch;
                    }
                }
            },
            err,
            None,
        )
        .map_err(|err| err.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn jitter_drops_oldest_at_three_frames() {
        let mut q = Queue::new(2);
        q.push_drop_old(&[1.0, 1.0]);
        q.push_drop_old(&[2.0, 2.0]);
        q.push_drop_old(&[3.0, 3.0]);
        q.push_drop_old(&[4.0, 4.0]);
        let mut out = [0.0; 2];
        assert!(q.pop(&mut out));
        assert_eq!(out, [2.0, 2.0]);
        assert!(q.pop(&mut out));
        assert_eq!(out, [3.0, 3.0]);
        assert!(q.pop(&mut out));
        assert_eq!(out, [4.0, 4.0]);
        assert!(!q.pop(&mut out));
    }

    #[test]
    fn playback_silence_when_empty() {
        let mut q = Queue::new(2);
        let mut out = [9.0, 9.0];
        assert!(!q.pop(&mut out));
        assert_eq!(out, [9.0, 9.0]);
    }
}
