# create autoscaling target for our ecs tasks so we can apply autoscaling policy to it
resource "aws_appautoscaling_target" "appautoscaling_target" {
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.app_ecs_cluster.name}/${aws_ecs_service.app_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity = 2
  max_capacity = 8

  depends_on = [aws_ecs_cluster.app_ecs_cluster, aws_ecs_service.app_ecs_service]
}

# create autoscaling policy to add additional tasks to service based on CPU usage metric
resource "aws_appautoscaling_policy" "app_scale_up" {
  name = "app-scale-up"
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.app_ecs_cluster.name}/${aws_ecs_service.app_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = "60"
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = 1
    }
  }

  depends_on = [aws_ecs_cluster.app_ecs_cluster, aws_ecs_service.app_ecs_service]
}

# create metric alarm used by autoscaling policy above
resource "aws_cloudwatch_metric_alarm" "app_cloudwatch_scale_up_alarm" {
  alarm_name = "app-scale-up-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = "80"

  dimensions = {
    ClusterName = aws_ecs_cluster.app_ecs_cluster.name
    ServiceName = aws_ecs_service.app_ecs_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_up.arn]
  depends_on = [aws_appautoscaling_policy.app_scale_up, aws_appautoscaling_target.appautoscaling_target]
}

# create autoscaling policy to remove tasks from service based on cloudwatch metrics
resource "aws_appautoscaling_policy" "app_scale_down" {
  name = "app-scale-down"
  service_namespace = "ecs"
  resource_id = "service/${aws_ecs_cluster.app_ecs_cluster.name}/${aws_ecs_service.app_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type = "ChangeInCapacity"
    cooldown = "60"
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment = -1
    }
  }
  depends_on = [aws_ecs_cluster.app_ecs_cluster, aws_ecs_service.app_ecs_service]
}

# create cloudwatch alarm to be used in autoscaling policy above
resource "aws_cloudwatch_metric_alarm" "app_cloudwatch_scale_down_alarm" {
  alarm_name = "app-scale-down-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/ECS"
  period = "60"
  statistic = "Average"
  threshold = "10"

  dimensions = {
      ClusterName = aws_ecs_cluster.app_ecs_cluster.name
      ServiceName = aws_ecs_service.app_ecs_service.name
  }

  alarm_actions = [aws_appautoscaling_policy.app_scale_down.arn]
  depends_on = [aws_appautoscaling_policy.app_scale_down, aws_ecs_cluster.app_ecs_cluster, aws_ecs_service.app_ecs_service]
}