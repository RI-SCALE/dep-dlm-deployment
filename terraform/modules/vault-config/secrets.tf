locals {
  # Same inputs as the testbed's modules/secrets/secrets.tf.
  idp_profile = one(values(jsondecode(file(
    "${path.module}/profiles/rucio/${var.scope_profile}/idpsecrets.json.example"
  ))))
  fts_resource_profile = try(regex(
    "OidcResourceIndicatorProfile=(\\S+)",
    file("${path.module}/profiles/fts/${var.scope_profile}/fts3config")
  )[0], "")

  config = merge({
    "server.cfg" = templatefile("${path.module}/templates/rucio.cfg.tftpl", {
      rucio_db_host          = var.rucio_db_host
      rucio_db_password      = var.rucio_db_password
      rucio_host             = var.rucio_host
      rucio_internal_host    = "http://localhost"
      bootstrap_userpass_pwd = var.bootstrap_userpass_pwd
      oidc_issuer            = var.oidc_issuer
      oidc_token_strategy    = var.token_mode == "managed" ? "exchange" : "client_credentials"
      oidc_expected_scope    = var.oidc_expected_scope
      oidc_expected_audience = var.oidc_expected_audience
    })
    "alembic.ini" = templatefile("${path.module}/templates/alembic.ini.tftpl", {
      rucio_db_host     = var.rucio_db_host
      rucio_db_password = var.rucio_db_password
    })
    "idpsecrets.json" = templatefile("${path.module}/templates/idpsecrets.json.tftpl", {
      oidc_issuer           = var.oidc_issuer
      oidc_client_id        = var.oidc_client_id
      oidc_client_secret    = var.oidc_client_secret
      rucio_public_hostname = var.rucio_host
      idp_scope             = local.idp_profile.scope
      idp_capabilities      = local.idp_profile.capabilities
    })
    "oidc-client.cfg" = templatefile("${path.module}/templates/oidc-client.cfg.tftpl", {
      rucio_host          = var.rucio_host
      oidc_issuer         = var.oidc_issuer
      oidc_expected_scope = var.oidc_expected_scope
      oidc_client_account = var.oidc_client_account
    })
    "userpass-client.cfg" = templatefile("${path.module}/templates/userpass-client.cfg.tftpl", {
      rucio_host        = var.rucio_host
      userpass_username = var.userpass_username
      userpass_password = var.userpass_password
      userpass_account  = var.userpass_account
    })
    "fts3restconfig" = templatefile("${path.module}/templates/fts3restconfig.tftpl", {
      site_name                = var.site_name
      fts_db_host              = var.fts_db_host
      fts_db_password          = var.fts_db_password
      oidc_issuer              = var.oidc_issuer
      allow_non_managed_tokens = var.token_mode == "unmanaged"
    })
    "fts3config" = templatefile("${path.module}/templates/fts3config.tftpl", {
      site_name            = var.site_name
      fts_db_host          = var.fts_db_host
      fts_db_password      = var.fts_db_password
      fts_resource_profile = local.fts_resource_profile
    })
    "docker-entrypoint.sh" = templatefile("${path.module}/templates/fts3-docker-entrypoint.sh.tftpl", {
      fts_db_host = var.fts_db_host
    })
    "rucio-db-dsn" = "postgres://rucio:${urlencode(var.rucio_db_password)}@${var.rucio_db_host}:5432/rucio?sslmode=disable"
    "fts-db-dsn"   = "mysql://fts:${urlencode(var.fts_db_password)}@${var.fts_db_host}:3306/fts"
    }, var.storage_ip == null ? {} : {
    "valstorage-ip" = var.storage_ip
  })

  # The keys the chart mounts (values.yaml certsMount, fts volumes).
  certs = {
    "hostcert.pem"            = file("${var.certs_dir}/hostcert.pem")
    "hostkey.pem"             = file("${var.certs_dir}/hostkey.pem")
    "hostcert_with_key.pem"   = file("${var.certs_dir}/hostcert_with_key.pem")
    "rucio_ca.pem"            = file("${var.certs_dir}/rucio_ca.pem")
    "tls_ca_bundle.pem"       = file("${var.certs_dir}/tls_ca_bundle.pem")
    "5fca1cb1.0"              = file("${var.certs_dir}/rucio_ca.pem")
    "5fca1cb1.signing_policy" = file("${var.certs_dir}/5fca1cb1.signing_policy")
  }
}

resource "vault_kv_secret_v2" "config" {
  mount     = vault_mount.kv.path
  name      = "${var.name_prefix}/config"
  data_json = jsonencode(local.config)
}

resource "vault_kv_secret_v2" "certs" {
  mount     = vault_mount.kv.path
  name      = "${var.name_prefix}/certs"
  data_json = jsonencode(local.certs)
}
