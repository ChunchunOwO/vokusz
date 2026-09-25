mod common;
use common::{authenticated_json_request, parse_body, TestServer};
use http::{Method, StatusCode};
use serde_json::json;
use tower::ServiceExt;

#[tokio::test]
async fn domain_roles_structure_and_isolation() {
    let server = TestServer::new().await;
    let owner = server.create_user_with_token("domain-owner").await;
    let senior = server.create_user_with_token("senior").await;
    let moderator = server.create_user_with_token("moderator").await;
    let guest = server.create_user_with_token("guest").await;
    let ordinary = server.create_user_with_token("ordinary").await;
    let domain = server.create_space(&owner.user.id, "domain").await;
    let other = server.create_space(&ordinary.user.id, "other").await;
    let roles = accordserver::db::roles::list_roles(server.pool(), &domain)
        .await
        .unwrap();
    assert_eq!(roles.len(), 4);
    for (user, name) in [
        (&senior, "高级管理员"),
        (&moderator, "管理员"),
        (&guest, "嘉宾"),
    ] {
        server.add_member(&domain, &user.user.id).await;
        let role = roles.iter().find(|r| r.name == name).unwrap();
        server.assign_role(&domain, &user.user.id, &role.id).await;
    }
    server.add_member(&domain, &ordinary.user.id).await;
    assert!(accordserver::db::members::get_member_role_ids(
        server.pool(),
        &domain,
        &ordinary.user.id
    )
    .await
    .unwrap()
    .is_empty());
    let permissions = accordserver::middleware::permissions::resolve_member_permissions(
        server.pool(),
        &domain,
        &moderator.user.id,
    )
    .await
    .unwrap();
    for permission in [
        "kick_members",
        "mute_members",
        "manage_messages",
        "moderate_members",
    ] {
        assert!(permissions.contains(&permission.to_owned()));
    }
    assert!(!permissions.contains(&"manage_channels".to_owned()));
    for user in [&moderator, &guest, &ordinary] {
        let response = server
            .router()
            .oneshot(authenticated_json_request(
                Method::POST,
                &format!("/api/v1/spaces/{domain}/channels"),
                &user.auth_header(),
                &json!({"name":"forbidden", "type":"category"}),
            ))
            .await
            .unwrap();
        assert_eq!(response.status(), StatusCode::FORBIDDEN);
    }
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::POST,
            &format!("/api/v1/spaces/{domain}/channels"),
            &senior.auth_header(),
            &json!({"name":"group", "type":"category"}),
        ))
        .await
        .unwrap();
    assert!(response.status().is_success());
    let body = parse_body(response).await;
    let category = body["data"]["id"].as_str().unwrap();
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::POST,
            &format!("/api/v1/spaces/{domain}/channels"),
            &senior.auth_header(),
            &json!({"name":"voice", "type":"voice", "parent_id":category}),
        ))
        .await
        .unwrap();
    assert!(response.status().is_success());
    let body = parse_body(response).await;
    let channel = body["data"]["id"].as_str().unwrap();
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::PATCH,
            &format!("/api/v1/channels/{channel}"),
            &senior.auth_header(),
            &json!({"parent_id":null}),
        ))
        .await
        .unwrap();
    assert!(response.status().is_success());
    assert!(
        accordserver::db::channels::get_channel_row(server.pool(), channel)
            .await
            .unwrap()
            .parent_id
            .is_none()
    );
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::POST,
            &format!("/api/v1/spaces/{other}/channels"),
            &ordinary.auth_header(),
            &json!({"name":"cross-domain", "parent_id":category}),
        ))
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::PATCH,
            &format!("/api/v1/spaces/{domain}/members/{}", owner.user.id),
            &moderator.auth_header(),
            &json!({"mute":true}),
        ))
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::FORBIDDEN);
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::POST,
            &format!("/api/v1/spaces/{domain}/roles"),
            &owner.auth_header(),
            &json!({"name":"活动嘉宾", "permissions":[]}),
        ))
        .await
        .unwrap();
    assert!(response.status().is_success());
    assert_eq!(parse_body(response).await["data"]["name"], "活动嘉宾");
}

#[tokio::test]
async fn community_admin_manages_domains_without_membership() {
    let server = TestServer::new().await;
    let owner = server.create_user_with_token("owner").await;
    let admin = server.create_admin_with_token("community-owner").await;
    let domain = server.create_space(&owner.user.id, "private").await;
    let roles = accordserver::db::roles::list_roles(server.pool(), &domain)
        .await
        .unwrap();
    let senior = roles.iter().find(|r| r.name == "高级管理员").unwrap();
    for path in [
        format!("/api/v1/spaces/{domain}"),
        format!("/api/v1/spaces/{domain}/roles"),
        format!("/api/v1/spaces/{domain}/channels"),
        format!("/api/v1/spaces/{domain}/members"),
    ] {
        let response = server
            .router()
            .oneshot(common::authenticated_request(
                Method::GET,
                &path,
                &admin.auth_header(),
            ))
            .await
            .unwrap();
        assert!(
            response.status().is_success(),
            "{path}: {}",
            response.status()
        );
    }
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::PATCH,
            &format!("/api/v1/spaces/{domain}/roles/{}", senior.id),
            &admin.auth_header(),
            &json!({"name":"高级管理组"}),
        ))
        .await
        .unwrap();
    assert!(response.status().is_success());
    let response = server
        .router()
        .oneshot(authenticated_json_request(
            Method::POST,
            &format!("/api/v1/spaces/{domain}/channels"),
            &admin.auth_header(),
            &json!({"name":"new-group", "type":"category"}),
        ))
        .await
        .unwrap();
    assert!(response.status().is_success());
}

#[tokio::test]
async fn voice_moves_require_domain_permission_hierarchy_and_current_source() {
    let server = TestServer::new().await;
    let owner = server.create_user_with_token("voice-owner").await;
    let moderator = server.create_user_with_token("voice-moderator").await;
    let target = server.create_user_with_token("voice-member").await;
    let domain = server.create_space(&owner.user.id, "voice-domain").await;
    for user in [&moderator, &target] { server.add_member(&domain, &user.user.id).await; }
    let roles = accordserver::db::roles::list_roles(server.pool(), &domain).await.unwrap();
    let role = roles.iter().find(|r| r.name == "管理员").unwrap();
    server.assign_role(&domain, &moderator.user.id, &role.id).await;
    let source = server.create_voice_channel(&domain, "source").await;
    let dest = server.create_voice_channel(&domain, "destination").await;
    let other = server.create_space(&owner.user.id, "other").await;
    let foreign = server.create_voice_channel(&other, "foreign").await;
    accordserver::voice::state::join_voice_channel(&server.state, &target.user.id, Some(&domain), &source, "session", true, false, false, false);
    for (actor, destination, from, expected) in [
        (&target, &dest, &source, StatusCode::FORBIDDEN),
        (&owner, &foreign, &source, StatusCode::BAD_REQUEST),
        (&moderator, &dest, &dest, StatusCode::BAD_REQUEST),
        (&moderator, &dest, &source, StatusCode::OK),
    ] {
        let response = server.router().oneshot(authenticated_json_request(Method::POST, &format!("/api/v1/channels/{destination}/voice/move"), &actor.auth_header(), &json!({"user_id":target.user.id,"source_channel_id":from}))).await.unwrap();
        assert_eq!(response.status(), expected);
        if expected == StatusCode::OK {
            assert!(parse_body(response).await["data"].is_null(), "credentials must not be returned to the moderator");
        }
    }
    let voice = server.state.voice_states.get(&target.user.id).unwrap();
    assert_eq!(voice.channel_id.as_deref(), Some(dest.as_str()));
    assert!(voice.self_mute);
    drop(voice);
    accordserver::voice::state::join_voice_channel(&server.state, &owner.user.id, Some(&domain), &source, "owner-session", false, false, false, false);
    let response = server.router().oneshot(authenticated_json_request(Method::POST, &format!("/api/v1/channels/{dest}/voice/move"), &moderator.auth_header(), &json!({"user_id":owner.user.id,"source_channel_id":source}))).await.unwrap();
    assert_eq!(response.status(), StatusCode::FORBIDDEN);
}
