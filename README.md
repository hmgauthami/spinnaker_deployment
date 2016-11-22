	Spinnaker Deployment	

OVERVIEW

Spinnaker is used as a continuous delivery platform for releasing software changes. The continuous delivery process begins with the creation of a deployable asset (such as a machine image, a JAR file, .deb file or a Docker image) and ends with a deployment to the cloud. 
Spinnaker provides two sets of features: 
• Cluster management, to configure, delete, disable, and deploy cloud resources like server groups, security groups, and load balancers, using strategies like blue/green deployments. 
• Deployment management, to create and manage continuous delivery workflows called pipelines. 
Pipelines are configurable, reusable processes that can be triggered by the completion of a Jenkins job, by a CRON expression, or even by another pipeline. Pipelines consist of stages, which are operations or phases in the continuous delivery process. Spinnaker comes with a number of stages, such as baking a machine image, deploying an image, running a Jenkins job, or waiting for user approval. Pipeline stages can be run in parallel or serially. 

	CLUSTER MANAGEMENT
Spinnaker's cluster management features are used to manage resources in the cloud.
•	Server Group: The base resource to be managed is the Server Group. A Server Group identifies the machine instance profile on which to execute images along with the number of instances, and is associated with a Load Balancer and a Security Group. A Server Group is also identified with basic configuration settings, such as user account information and the region/zone in which images are deployed. When deployed, a Server Group is a collection of virtual machines running software.
 
•	Security Group: A Security Group defines network traffic access. It is effectively a set of firewall rules defined by an IP range (CIDR) along with a communication protocol (e.g., TCP) and port range.
•	Load Balancer: A Load Balancer is associated with an ingress protocol and port range, and balances traffic among instances in the corresponding Server Group. Optionally, you can enable health checks for a load balancer, with flexibility to define health criteria and specify the health check endpoint.
•	Cluster: A Cluster is a user-defined, logical grouping of Server Groups in Spinnaker.

	DEPLOYMENT MANAGEMENT
Spinnaker's deployment management features are used to construct and manage continuous delivery workflows.
•	Pipeline: Pipelines are the key deployment management construct in Spinnaker. They are defined by a sequence of stages, along with automated triggers (optional) that kick off the pipeline, parameters that get passed to all stages in the pipeline, and can be configured to issue notifications as the pipeline executes.
	Automatic triggers can be a Jenkins job, a CRON schedule, or another pipeline. You can also manually start a pipeline. Notifications can be sent out to email, SMS or HipChat on pipeline start/complete/fail.
 

Fig 1. Deployment Management with Spinnaker




ARCHETECTURE 
Deploying this Quick Start with the default parameters builds the following Spinnaker environment in the AWS Cloud.

 

Figure 2: Architecture for Spinnaker on AWS

Amazon Web Services Setup
If you'd like to have Spinnaker deploy to and manage clusters on AWS, you'll need to have an AWS project set up. If you've already got one, please skip to the next step. Otherwise, please follow the
instructions below.
Keep in mind that naming of your entities in AWS is important as Spinnaker will use them to populate available resource lists in the Spinnaker UI.
Sign into the AWS console and let AWS pick a default region where your project resources will be allocated. In the rest of this tutorial, we'll assume that the region
assigned is us-west-2. If the region selected for your project is different from this, please substitute your region everywhere us-west-2 appears below.
Also, in the instructions below, we'll assume that your AWS account name is my-aws-account. Wherever you see my-aws-account appear below, please replace it with your AWS account name.

1.	Create VPC.
o	Goto Console > VPC.
o	Click on Start VPC Wizard.
o	On the Step 1: Select a VPC Configuration screen, make sure that VPC with a Single Public Subnet is highlighted and click Select.
o	Name your VPC. Enter defaultvpc in the VPC name field.
o	Enter defaultvpc.internal.us-west-2 for Subnet name.
o	Click Create VPC.
2.	Create an EC2 role.
o	Goto Console > AWS Identity & Access Management > Roles.
o	Click Create New Role.
o	Set Role Name to BaseIAMRole. Click Next Step.
o	On Select Role Type screen, hit Select for Amazon EC2.
o	Click Next Step.
o	On Review screen, click Create Role.
o	EC2 instances launched with Spinnaker will be associated with this role.
3.	Create an EC2 Key Pair for connecting to your instances.
o	Goto Console > EC2 > Key Pairs.
o	Click Create Key Pair.
o	Name the key pair my-aws-account-keypair. (Note: this must match your account name plus "-keypair")
o	AWS will download file my-aws-account-keypair.pem to your computer. chmod 400 the file.
4.	Create AWS credentials for Spinnaker.
o	Goto Console > AWS Identity & Access Management > Users > Create New Users. Enter a username and hit Create.
o	Create an access key for the user. Click Download Credentials,
then Save the access key and secret key into
~/.aws/credentials on your machine as shown
here.
o	Click Close.
o	Click on the username you entered for a more detailed screen.
o	On the Summary page, click on the Permissions tab.
o	Click Attach Policy.
o	Click the checkbox next to PowerUserAccess, then click Attach Policy.
o	Click on the Inline Policies header, then click the link to create an inline policy.
o	Click Select for Policy Generator.
o	Select AWS Identity and Access Management from the AWS Service pulldown.
o	Select PassRole for Actions.
o	Type (the asterisk character) in the *Amazon Resource Name (ARN) box.
o	Click Add Statement, then Next Step.
o	Click Apply Policy.
Deploying Spinnaker
Once you've setup your Cloud provider environment you are ready to install and run Spinnaker. Your choice of where to run Spinnaker does not affect your choice of deployment targets, but some of the hosted turn-key solutions are preconfigured to deploy to a limited set of platforms.

SPINNAKER COMPONENTS
Spinnaker is composed of several micro services that provide each piece of the functionality of the system.
Component Name	Functionality	Default Port
Deck	User interface.	9000
Gate	Api gateway. All external requests to Spinnaker are directed through Gate.	8084
Orca	Orchestration of pipelines and ad hoc operations.	8083
Clouddriver	Interacts with and mutates infrastructure on underlying cloud providers.	7002
Rosco	Machine image bakery. A machine image is a static view of the state and disk of a machine that can be 'deployed' into a running instance. Representation varies by cloud provider.	8087
Front50	Interface to persistent storage, such as Amazon S3 or Google Cloud Storage.	8080
Igor	Interface to Jenkins. Can both listen to and fire Jenkins jobs and collect contextual job and build information.	8088
Echo	Event bus for notifications and triggers. Triggers are things like git commits, Jenkins jobs finishing and other Spinnaker pipelines finishing. Notifications can send emails, slack notifications, SMS messages, etc.	8089
Spinnaker can be deployed on any target environment, and can manage infrastructure in any of the supported cloud providers. For instance, you can deploy your Spinnaker cluster to Google Cloud Platform, but manage infrastructure on Amazon Web Services and Kubernetes. Next, we'll step through the configuration for each of the supported target environments.
Create an AWS virtual machine.
1.	Goto AWS Console > AWS Identity & Access
Management > Roles.
o	Click on Create New Role.
o	Type "spinnakerRole" in the Role Name field. Hit Next Step.
o	Click Select for the Amazon EC2 service.
o	Select the checkbox next to PowerUserAccess, then click
Next Step, followed by Create Role.
o	Click on the role you created.
o	Click on the Inline Policies header, then click the link to create an inline policy.
o	Click Select for Policy Generator.
o	Select AWS Identity and Access Management from the AWS Service pulldown.
o	Select PassRole for Actions.
o	Type (the asterisk character) in the *Amazon Resource Name (ARN) box.
o	Click Add Statement, then Next Step.
o	Click Apply Policy.
o	Go to AWS Console > EC2.
o	Click Launch Instance.
o	Click Community AMIs then
o	If the default region where your resources were allocated in Step 1 is us-west-2, click Select for the spinnaker_jenkins ami-5632fb36 image. 
o	Under Step 2: Choose an Instance Type, click the radio button
for m4.xlarge, then click Next: Configure Instance Details.
o	Set the Auto-assign Public IP field to Enable, and the IAM
role to "spinnakerRole".
o	Click Review and Launch.
o	Click Launch.
Once the instance is launched Access spinnaker using Route53 Domain name.
https://<domainname>
https://builddeploy.modeler.gy/ 
Credentials: logikoma / password
