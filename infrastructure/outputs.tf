output "endpoint_url" {
  value = "${aws_api_gateway_stage.quable_api.invoke_url}/${var.endpoint_path}"
}