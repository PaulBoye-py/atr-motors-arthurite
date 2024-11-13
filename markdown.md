# Technical Documentation: Migration of atrmotors.com to AWS Cloud Infrastructure

## Project Overview

**Objective:**  
Migrate atrmotors.com from Hostinger to AWS to improve scalability, reliability, and performance for a luxury car shop website. The migration will utilize various AWS services to establish a secure, scalable, and highly available architecture, minimizing downtime and ensuring a seamless user experience.

**Goals:**

- Achieve improved load times and performance stability.
- Enhance security with AWS native services.
- Enable scaling for future growth.
- Reduce downtime during migration.

---

## Table of Contents

1. [Target Architecture](#target-architecture)
2. [AWS Services Utilized](#aws-services-utilized)
3. [Migration Phases](#migration-phases)
4. [Potential Challenges and Mitigations](#potential-challenges-and-mitigations)
5. [Rollback Plan](#rollback-plan)
6. [Success Criteria](#success-criteria)
7. [Post-Migration Tasks](#post-migration-tasks)
8. [Budget Considerations](#budget-considerations)
9. [Appendix: Technical Details](#appendix-technical-details)

---

## Target Architecture

The following AWS services and resources will be configured in the target architecture:

![AWS Target Architecture](/assets/aws_architecture.png)

### Components

- **Route 53**: DNS management and domain registration.
- **CloudFront**: Content Delivery Network (CDN) for reduced latency.
- **Application Load Balancer (ALB)**: Distributes incoming traffic across multiple instances.
- **EC2**: Hosts the main application.
- **RDS**: MySQL database for dynamic content.
- **S3**: Storage for static assets such as images and scripts.
- **AWS WAF**: Web Application Firewall for protection against common attacks.
- **CloudWatch**: Monitoring for performance metrics, logs, and alerts.

---

## AWS Services Utilized

### 1. **Compute & Storage**

- **EC2**: Runs the website’s web server on a `t3.small` instance for efficient performance.
- **RDS**: Provides a managed MySQL database on a `db.t3.small` instance, with automated backups and snapshots.
- **S3**: Stores static assets (images, JavaScript, CSS files), allowing faster content delivery via CloudFront.

### 2. **Network & Security**

- **Route 53**: Handles DNS routing, enabling efficient domain management and connection reliability.
- **CloudFront**: CDN that reduces latency by caching static assets closer to users, with SSL/TLS termination for secure HTTPS connections.
- **Virtual Private Cloud (VPC)**: Organizes network architecture into public and private subnets for security and performance optimization.
- **Security Groups and Network Access Control Lists (NACLs)**: Controls inbound/outbound traffic at the instance and subnet levels.

### 3. **Monitoring & Management**

- **CloudWatch**: Provides metrics and alerts for monitoring CPU usage, network traffic, and error rates.
- **AWS Backup**: Automates backup processes for both EC2 and RDS, ensuring data redundancy and reliability.
- **AWS WAF**: Web Application Firewall to protect against common threats like SQL injection and cross-site scripting.

---

## Migration Phases

![Migration Phases](/assets/atrmotors_migration_timeline.png)

### Phase 1: Preparation (Days 1-2)

- Create AWS account if not existing.
- Set up IAM roles and permissions.
- Configure Virtual Private Cloud (VPC) and networking components.
- Perform a full backup of the website and MySQL database from Hostinger.
- Document existing DNS settings and SSL configurations.

### Phase 2: Infrastructure Setup (Days 3-4)

- Deploy EC2 instance with necessary configurations.
- Set up RDS MySQL instance with initial database.
- Configure an S3 bucket for static asset storage.
- Set up and configure ALB, CloudFront distribution, and associated security groups.

### Phase 3: Application Migration (Days 5-6)

- Transfer website files to EC2.
- Migrate the database from Hostinger to RDS.
- Update application configurations to connect with the new database endpoint.
- Set up SSL certificates using ACM (AWS Certificate Manager) and configure CloudFront for static assets.

### Phase 4: Testing (Day 7)

- Perform load testing and verify all functionalities.
- Test backup and restore procedures.
- Validate SSL configurations and security settings.
- Check CloudWatch alerts for performance monitoring.

### Phase 5: Cutover (Day 8)

- Reduce DNS Time-to-Live (TTL) values in Route 53.
- Update DNS records to point to AWS servers.
- Monitor DNS propagation and application performance.
- Confirm all services are fully functional post-migration.

---

## Potential Challenges and Mitigations

1. **Downtime Minimization**
   - **Challenge**: Ensuring minimal service interruption.
   - **Mitigation**: Use DNS TTL adjustments and maintain parallel environments during testing.

2. **Data Consistency**
   - **Challenge**: Avoid data loss during database migration.
   - **Mitigation**: Use AWS Database Migration Service (DMS) or point-in-time snapshots.

3. **DNS Propagation**
   - **Challenge**: Delays in DNS changes taking effect.
   - **Mitigation**: Schedule migration during off-peak hours and lower TTL in advance.

4. **SSL Certificate Setup**
   - **Challenge**: Maintaining SSL security during cutover.
   - **Mitigation**: Prepare SSL in ACM before cutover and validate after DNS update.

---

## Rollback Plan

1. Maintain Hostinger environment for 7 days after migration.
2. Keep a full backup of the website and database from Hostinger.
3. Retain original DNS configurations for immediate rollback.
4. Prepare reverse DNS update procedure to revert traffic back to Hostinger if necessary.

---

## Success Criteria

- Website functionality matches or exceeds existing performance.
- Load time is consistently under 3 seconds.
- SSL certificate is correctly configured with no security issues.
- Monitoring and alerting systems are active.
- Data integrity and completeness with zero data loss.
- Automated backups verified and operational.

---

## Post-Migration Tasks

1. **Monitoring**: Monitor site performance and AWS resources for 48 hours post-migration.
2. **Documentation**: Update technical documentation to reflect the new architecture and configurations.
3. **Decommissioning**: Terminate Hostinger services after 7 days if migration is confirmed successful.
4. **Backup Reviews**: Schedule regular backup checks and retention reviews.
5. **Training**: Provide AWS training for the management team to handle ongoing operations.

---

## Budget Considerations

### Estimated Monthly Cost Breakdown

| SERVICE      | DETAILS                            | EST. COST (USD) | FREE TIER ELIGIBLE          |
|--------------|------------------------------------|-----------------|-----------------------------|
| EC2          | 4x t3.small ($0.025/hr)            | ~$73.00         | Yes - 750 hrs t2.micro      |
| RDS          | Primary db.t3.small ($0.036/hr)    | ~$26.28         | Yes - 750 hrs t2.micro      |
| RDS          | Standby db.t3.small ($0.036/hr)    | ~$26.28         | No                          |
| NAT Gateway  | 2x NAT ($0.045/hr + data)          | ~$71.00         | No                          |
| SES          | 2 email addresses (50K emails)     | ~$5.50          | Yes - 62K emails            |
| WAF          | Per rule and requests              | ~$11.00         | No                          |
| CloudWatch   | Basic monitoring + logs            | ~$16.00         | Yes - Basic metrics         |
| ALB          | 2x Load balancers ($0.0225/hr)     | ~$35.00         | No                          |
| Data Transfer| Between AZs and internet           | ~$32.00         | Varies                      |
| **Total Monthly Costs** |                          | **~$299.81**    |                             |

**Total Estimated Cost with Free Tier**: scaling up to $300 with full instance usage.

By utilizing the AWS Free Tier, we can reduce the initial monthly cost and gradually transition to higher-performance instances as the business grows.

---

## Communication Plan

- **Daily Updates**: Send daily status updates to all stakeholders during migration.
- **Issue Notifications**: Notify stakeholders immediately of any critical issues.
- **Documentation**: Record and share all configuration changes and decisions.
- **Weekly Review Meetings**: Hold weekly review meetings to discuss ongoing AWS performance and adjustments.

---

## Appendix: Technical Details

1. **VPC Configuration**
   - 1 public and 1 private subnet for network segmentation.
   - Enable NAT gateway for secure internet access in the private subnet.

2. **Security Groups & NACLs**
   - Define security groups for EC2 and RDS with port restrictions.
   - Apply NACLs for additional subnet-level security.

3. **IAM Roles & Policies**
   - Assign roles for EC2, RDS, and S3 with least privilege access.
   - Create IAM policies for admin and developer access.

4. **Database Migration**
   - Utilize AWS DMS or point-in-time snapshot to transition MySQL data.

5. **SSL Configuration**
   - Use AWS ACM for SSL certificates on CloudFront and ALB.
   - Validate SSL status post-migration.

---
