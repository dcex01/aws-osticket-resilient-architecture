# Highly Available osTicket on AWS with ECS, Terraform, Prometheus and Grafana

Production-style proof of concept for deploying a resilient osTicket platform on AWS using Infrastructure as Code, container orchestration, observability and automated recovery.

## Architecture

The solution uses:

- Amazon VPC with segmented public, application and database subnets
- Amazon ECS on EC2
- Auto Scaling Group with multiple EC2 instances
- Application Load Balancer
- Amazon RDS MySQL
- Amazon ECR
- Amazon S3
- AWS Secrets Manager
- AWS Systems Manager Session Manager
- Prometheus
- Node Exporter
- cAdvisor
- Grafana
- Amazon SNS for alert notifications
- Terraform for Infrastructure as Code

## Key Features

- Highly available osTicket deployment across multiple ECS container instances
- Load balancing and health checks through an Application Load Balancer
- Automatic EC2 replacement using Auto Scaling
- Persistent MySQL database using Amazon RDS
- Sensitive credentials stored in AWS Secrets Manager
- Container and host monitoring with Prometheus, Node Exporter and cAdvisor
- Grafana dashboards for EC2 and osTicket metrics
- Grafana persistent configuration stored in RDS MySQL
- Alerting pipeline using Grafana Alerting and Amazon SNS
- Email notifications for degraded osTicket capacity
- Infrastructure deployed and managed with Terraform

## Monitoring

### EC2 Infrastructure Dashboard

The infrastructure dashboard includes:

- CPU Usage
- Memory Usage
- Disk Usage
- Network RX/TX

### osTicket ECS Dashboard

The application dashboard includes:

- osTicket CPU Usage
- osTicket Memory Usage
- Network Traffic
- Active Instances
- Container Uptime

## Resilience Testing

The platform was validated using controlled failure scenarios.

### ECS Workload Degradation

The osTicket ECS service was temporarily reduced from two running tasks to one.

Expected behavior:

1. Prometheus detected one active osTicket instance.
2. Grafana changed the alert state from Normal to Firing.
3. Grafana published the notification to Amazon SNS.
4. SNS delivered an email notification.
5. The ECS service was restored to two tasks.
6. Grafana transitioned through Recovering and returned to Normal.

### EC2 Node Failure

A complete ECS container instance was stopped to simulate infrastructure failure.

Observed behavior:

1. The Application Load Balancer removed the failed target.
2. Traffic continued through the remaining healthy target.
3. osTicket remained accessible through the ALB.
4. The Auto Scaling Group detected unhealthy capacity.
5. A replacement EC2 instance was launched.
6. The new instance joined the ECS cluster.
7. ECS restored the osTicket service to the desired count.
8. The new target was registered in the ALB.
9. The Target Group returned to two healthy targets.

## Security

- No AWS credentials are stored in the repository.
- Secrets are retrieved from AWS Secrets Manager.
- ECS Task Roles provide temporary AWS credentials.
- Grafana uses a dedicated IAM Task Role for SNS publishing.
- Administrative access to EC2 instances is performed through AWS Systems Manager instead of SSH exposure.
- Terraform state and variable files containing environment-specific values are excluded from Git.

## Repository Structure

```text
.
├── docker/
│   ├── osticket/
│   └── prometheus/
├── environments/
│   └── dev/
├── modules/
│   ├── alb/
│   ├── ecr/
│   ├── ecs/
│   ├── ecs_service/
│   ├── monitoring/
│   ├── networking/
│   ├── rds/
│   ├── s3/
│   └── secrets/
├── .gitignore
└── README.md