output "guardduty_detector_id" {
  description = "The ID of the GuardDuty detector"
  value       = aws_guardduty_detector.primary.id
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for GuardDuty findings"
  value       = aws_sns_topic.guardduty_alerts.arn
}