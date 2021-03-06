# create aws log group for our fargate tasks
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/ecs/app"
  retention_in_days = 30
}

# create a log stream using newly created log group
resource "aws_cloudwatch_log_stream" "app_log_stream" {
  name           = "app-log-stream"
  log_group_name = aws_cloudwatch_log_group.app_log_group.name

  depends_on = [aws_cloudwatch_log_group.app_log_group]
}