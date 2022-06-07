use std::path::Path;

use bson::doc;

use crate::MongoCryptBuilder;
use crate::error::Result;

mod binary;
mod error;

#[test]
fn builder_setopts() -> Result<()> {
    let builder = MongoCryptBuilder::new();
    builder
        .log_handler(|level, msg| println!("{:?}: {}", level, msg))?
        .kms_providers(&doc! {})?
        .schema_map(&doc! {})?
        .encrypted_field_config_map(&doc! {})?
        .append_crypt_shared_lib_search_path(Path::new("$SYSTEM"))?
        .set_crypt_shared_lib_path_override(Path::new("$ORIGIN"))?
        .use_need_kms_credentials_state()
    ;
    Ok(())
}

#[test]
fn builder_build() -> Result<()> {
    let _crypt = MongoCryptBuilder::new()
        .kms_provider_aws("example", "example")?
        .build()?;
    Ok(())
}