module "file_cache" {
  source = "git::https://github.com/MetroStar/terraform-external-file-cache.git?ref=2.1.3"

  python_cmd = var.python_cmd
  uris       = keys(var.uri_map)

  s3_endpoint_url = var.s3_endpoint_url
}

resource "aws_s3_object" "file" {
  # Construct a resource id that represents the bucket and key
  for_each = { for uri, key in var.uri_map : "s3://${var.bucket_name}/${var.prefix}${key}${basename(uri)}" => uri }

  bucket      = var.bucket_name
  key         = local.uri_objects[each.value].key
  source      = module.file_cache.filepaths[each.value]
  source_hash = filemd5(module.file_cache.filepaths[each.value])
}

resource "aws_s3_object" "hash" {
  # Construct a resource id that represents the bucket and key
  for_each = var.create_hashes ? { for uri, key in var.uri_map : "s3://${var.bucket_name}/${var.prefix}${key}${basename(uri)}.SHA512" => uri } : {}

  bucket       = var.bucket_name
  key          = "${local.uri_objects[each.value].key}.SHA512"
  content      = local.uri_objects[each.value].hash_content
  content_type = "application/octet-stream"
  source_hash  = md5(local.uri_objects[each.value].hash_content)
}

locals {
  uri_objects = {
    for uri, filepath in module.file_cache.filepaths : uri => {
      key          = "${var.prefix}${var.uri_map[uri]}${basename(filepath)}"
      hash_content = "${filesha512(filepath)} ${basename(filepath)}"
    }
  }
}
