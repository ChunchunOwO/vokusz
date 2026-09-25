use cpal::traits::{DeviceTrait, HostTrait};
use cpal::Host;
use serde_json::{Value, json};
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{Duration, Instant};

const CACHE_TTL: Duration = Duration::from_millis(1500);
static CACHE: Mutex<Option<(Instant, Value)>> = Mutex::new(None);

pub fn list() -> Result<Value, String> {
    let mut cache = CACHE.lock().unwrap_or_else(|err| err.into_inner());
    if let Some((at, value)) = cache.as_ref()
        && at.elapsed() < CACHE_TTL
    {
        return Ok(value.clone());
    }
    let value = list_uncached()?;
    *cache = Some((Instant::now(), value.clone()));
    Ok(value)
}

pub fn invalidate() {
    *CACHE.lock().unwrap_or_else(|err| err.into_inner()) = None;
}

pub fn validate(kind: &str, id: Option<&str>) -> Result<(), String> {
    let Some(id) = id.map(str::trim).filter(|value| !value.is_empty()) else {
        return Ok(());
    };
    let list = list()?;
    let key = if kind == "in" { "inputs" } else { "outputs" };
    let found = list
        .get(key)
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
        .any(|device| device["id"] == id);
    if found {
        Ok(())
    } else {
        Err(format!("unknown_{kind}put_device"))
    }
}

pub fn input(host: &Host, id: Option<&str>) -> Result<cpal::Device, String> {
    pick(
        id,
        "in",
        host.default_input_device(),
        host.input_devices().map_err(|err| err.to_string())?,
        "no_input_device",
    )
}

pub fn output(host: &Host, id: Option<&str>) -> Result<cpal::Device, String> {
    pick(
        id,
        "out",
        host.default_output_device(),
        host.output_devices().map_err(|err| err.to_string())?,
        "no_output_device",
    )
}

fn pick(
    id: Option<&str>,
    prefix: &str,
    default: Option<cpal::Device>,
    devices: impl Iterator<Item = cpal::Device>,
    missing: &str,
) -> Result<cpal::Device, String> {
    let Some(id) = id.map(str::trim).filter(|value| !value.is_empty()) else {
        return default.ok_or_else(|| missing.into());
    };
    let mut seen: HashMap<String, u32> = HashMap::new();
    for device in devices {
        let name = device.name().unwrap_or_else(|_| "Unknown".into());
        let count = seen.entry(name.clone()).or_insert(0);
        *count += 1;
        let generated = if *count == 1 {
            format!("{prefix}:{name}")
        } else {
            format!("{prefix}:{name}:{count}")
        };
        if generated == id {
            return Ok(device);
        }
    }
    Err(format!("unknown_{prefix}put_device"))
}

fn list_uncached() -> Result<Value, String> {
    let host = cpal::default_host();
    let inputs = collect(
        host.input_devices()
            .map_err(|err| err.to_string())?,
        host.default_input_device(),
        "in",
    )?;
    let outputs = collect(
        host.output_devices()
            .map_err(|err| err.to_string())?,
        host.default_output_device(),
        "out",
    )?;
    Ok(json!({ "inputs": inputs, "outputs": outputs }))
}

fn collect(
    devices: impl Iterator<Item = cpal::Device>,
    default: Option<cpal::Device>,
    prefix: &str,
) -> Result<Vec<Value>, String> {
    let default_name = default.and_then(|device| device.name().ok());
    let mut seen: HashMap<String, u32> = HashMap::new();
    let mut out = Vec::new();
    for device in devices {
        let name = device.name().unwrap_or_else(|_| "Unknown".into());
        let count = seen.entry(name.clone()).or_insert(0);
        *count += 1;
        let id = if *count == 1 {
            format!("{prefix}:{name}")
        } else {
            format!("{prefix}:{name}:{count}")
        };
        let label = if *count == 1 {
            name.clone()
        } else {
            format!("{name} ({count})")
        };
        let is_default = default_name.as_ref() == Some(&name) && *count == 1;
        out.push(json!({ "id": id, "name": label, "default": is_default }));
        if out.len() >= 64 {
            break;
        }
    }
    Ok(out)
}

pub fn parse_device_id(id: &str, prefix: &str) -> Option<(String, u32)> {
    let rest = id
        .strip_prefix(&format!("{prefix}:"))
        .unwrap_or(id)
        .trim();
    if rest.is_empty() {
        return None;
    }
    if let Some((name, n)) = rest.rsplit_once(':')
        && let Ok(index) = n.parse::<u32>()
        && index >= 2
        && !name.is_empty()
    {
        return Some((name.to_string(), index));
    }
    Some((rest.to_string(), 1))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_named_and_duplicate_device_ids() {
        assert_eq!(
            parse_device_id("in:MacBook Pro Microphone", "in"),
            Some(("MacBook Pro Microphone".into(), 1))
        );
        assert_eq!(parse_device_id("out:Speakers:2", "out"), Some(("Speakers".into(), 2)));
        assert_eq!(parse_device_id("", "in"), None);
        assert_eq!(parse_device_id("in:", "in"), None);
    }

    #[test]
    fn list_returns_object_or_error() {
        match list() {
            Ok(value) => {
                assert!(value.get("inputs").and_then(Value::as_array).is_some());
                assert!(value.get("outputs").and_then(Value::as_array).is_some());
            }
            Err(err) => assert!(!err.is_empty()),
        }
    }
}
