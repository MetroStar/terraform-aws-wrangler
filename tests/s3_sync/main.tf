terraform {
  required_version = ">= 0.12"
}

data "terraform_remote_state" "prereq" {
  backend = "local"
  config = {
    path = "prereq/terraform.tfstate"
  }
}

module "s3_sync" {
  source = "../../"

  bucket_name = data.terraform_remote_state.prereq.outputs.bucket_target.id

  uri_map = {
    # Construct map of uri => key_path without filename
    for object in data.terraform_remote_state.prereq.outputs.s3_objects.keys :
    "s3://${data.terraform_remote_state.prereq.outputs.bucket_source.id}/${object}" =>
    trimsuffix(
      object, # Remove the filename from the key path
      element(split("/", object), length(split("/", object)) - 1)
    )
  }
}

output "s3_sync" {
  value = module.s3_sync
}
