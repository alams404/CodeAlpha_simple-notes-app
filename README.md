CodeAlpha Notes App on Azure
A simple notes application that I containerised with Docker, provisioned on Azure with Terraform, and deployed automatically with GitHub Actions. Every push to the main branch builds a new image, sends it to Azure Container Registry, and updates the live web app.
This project is part of my cloud engineering internship work with CodeAlpha, and I documented the whole journey, including the mistakes, because that is where most of the learning happened.
Author: Kingsley Alamanjo Ibeabuchi
GitHub: alams404
What the project does
The app lets a user write a note with a title and some content, save it, and see all saved notes on the same page. The notes are stored in a PostgreSQL database, so they are still there after a page refresh or an app restart.
The app exposes a small API at /api/notes and serves a simple front end from the public folder.
Add a screenshot of the finished app here:
�
Load image
Tools and services used
Node.js and Express for the web server
PostgreSQL (Azure Database for PostgreSQL Flexible Server) for storage
Docker for packaging the app
Azure Container Registry to hold the Docker image
Azure App Service (Linux, container) to run the app
Terraform to create all the Azure resources
GitHub Actions for the CI/CD pipeline
Azure CLI for setup and troubleshooting
Git Bash on Windows as my terminal
How it fits together
I push code to the main branch on GitHub.
GitHub Actions starts the workflow and signs in to Azure with a service principal.
The workflow builds the Docker image and pushes it to Azure Container Registry.
The workflow tells the Azure web app to pull the new image.
The web app starts the container and connects to PostgreSQL.
A final step checks that the site answers before the run is marked as passed.
Add your architecture sketch or Azure portal overview here:
�
Load image
Azure resources
Everything lives in one resource group called codealpha-rg. Terraform builds a random suffix into some names so they stay unique, which means the exact names change each time the infrastructure is destroyed and created again. These are the names from my deployment:
Resource group: codealpha-rg
Container registry: codealphaacrz9mqa
Web app: codealpha-app-z9mqa
PostgreSQL server: codealpha-pg-z9mqa
Database: codealpha-db
Add a screenshot of the resource group in the Azure portal:
�
Load image
Project layout
.
├── .github/workflows/codealpha.yaml   the CI/CD pipeline
├── public/                            front end files
├── server.js                          Express app and database setup
├── Dockerfile                         how the image is built
├── main.tf                            Azure resources
├── variables.tf                       prefix, port, image name and other inputs
├── output.tf                          values printed after apply
└── .gitignore                         keeps state files and secrets out of Git
Before you start
You need these installed and ready:
An Azure account with an active subscription
Azure CLI, signed in with az login
Terraform
Docker
Git, and a GitHub account with a repository for the project
Step 1: Create the infrastructure with Terraform
From the project folder, run:
terraform init
terraform plan
terraform apply
Type yes when Terraform asks. My apply created 8 resources. When it finishes, the outputs show the registry name and the web app name. I need both of them for the GitHub secrets later.
Add a screenshot of the finished apply and the outputs:
�
Load image
Step 2: Create a service principal for GitHub
GitHub Actions needs permission to work inside the resource group. I created a service principal and limited it to codealpha-rg. I gave it the Contributor role because that is enough for deployments and much safer than Owner.
First get the subscription ID:
az account show --query id -o tsv
Then create the service principal:
az ad sp create-for-rbac --name "codealpha" --role contributor --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/codealpha-rg --json-auth
The command prints a block of JSON. This is the only time the client secret is shown, so copy all of it right away. Never paste it into a chat, a screenshot, or a file in the repository.
If the role assignment did not stick, you can add it again:
az role assignment create --assignee <CLIENT_ID> --role contributor --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/codealpha-rg
Add a screenshot of the role assignment output with the IDs hidden:
�
Load image
Step 3: Add the GitHub secrets
In the repository, open Settings, then Secrets and variables, then Actions, and create three repository secrets:
AZURE_CREDENTIALS with the full JSON from the previous step
ACR_NAME with the registry name only, for example codealphaacrz9mqa, without .azurecr.io
WEBAPP_NAME with the web app name, for example codealpha-app-z9mqa
Type the names and values carefully. A hidden space or line break at the end of a value will break the pipeline in confusing ways, and I found that out the hard way.
Add a screenshot of the secrets list. Only the names are visible, which is fine:
�
Load image
Step 4: The pipeline
The workflow lives in .github/workflows/codealpha.yaml and runs on every push to main. It has these steps:
Check out the code
Log in to Azure using AZURE_CREDENTIALS
Log in to the container registry
Build the Docker image and push it with two tags, the commit SHA and latest
Deploy the image to the web app
Check the site and fail the run if it does not respond
Add a screenshot of the workflow file in your editor:
�
Load image
Step 5: Deploy
Commit and push to main:
git add .
git commit -m "deploy notes app"
git pull --rebase origin main
git push origin main
Open the Actions tab on GitHub and watch the run. When every step has a green tick, the deployment is finished.
Add a screenshot of the green run:
�
Load image
Step 6: Check the live site
Open https://<your web app name>.azurewebsites.net in a browser. The first start can take a couple of minutes while Azure pulls the image. Add a note, then refresh the page. If the note is still there, the app is saving to PostgreSQL correctly.
Add a screenshot of a saved note after a refresh:
�
Load image
Problems I ran into and how I fixed them
This part took the most time, and it taught me more than the happy path did.
1. The service principal command kept failing with MissingSubscription
My first attempts had a stray full stop at the end of the command, then I wrote /subscription/ instead of /subscriptions/, and later I used only the ID without the path. The scope has to be the full path starting with /subscriptions/.
2. Git Bash changed my Azure paths
Git Bash on Windows treats anything that starts with a slash as a file path and rewrites it before the Azure CLI sees it. That produced the same MissingSubscription error even with a correct command. Putting MSYS_NO_PATHCONV=1 in front of the command switched the rewriting off.
3. Placeholders typed literally
I once ran a command with <clientId> exactly as written. The terminal read the angle brackets as file redirects. Placeholders have to be replaced by real values, brackets and all.
4. A typo in the workflow on the secrets line
I wrote screts instead of secrets, and GitHub rejected the whole workflow before running anything.
5. Hidden characters in a secret
The registry login failed because the ACR_NAME secret carried an extra line break, so Azure searched for a registry with a name that did not exist. Retyping the secret by hand fixed it.
6. A typo in a variable name
The registry login step defined ACR_USER, but the next line used ACR_UASER. The empty variable gave the error "Must provide username with password stdin".
7. A missing closing quote
The build step failed with "unexpected EOF while looking for matching quote". One line was missing its closing quotation mark.
8. Git push rejected
I had edited the .gitignore file on GitHub, so my local copy was behind. Running git pull --rebase origin main before pushing solved it.
9. The site showed 503 Service Unavailable
The pipeline was green but the container crashed on startup. I turned on container logging, downloaded the logs with az webapp log download, and read the end of the Docker log. It showed that the app could not connect to PostgreSQL. This was the biggest lesson of the project: a green pipeline does not mean a working app, and the container log tells you what is really wrong.
10. The database refused the connection
The log said there was no pg_hba.conf entry and "no encryption". Two things were missing. The Azure PostgreSQL server requires SSL, and my server.js only turns SSL on when the environment variable DB_SSL equals true. I also needed a firewall rule that lets Azure services reach the database. These were the fixes:
az webapp config appsettings set --name <web app name> --resource-group codealpha-rg --settings DB_SSL=true
az postgres flexible-server firewall-rule create --resource-group codealpha-rg --server-name <server name> --name AllowAzure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
az webapp restart --name <web app name> --resource-group codealpha-rg
After that the app loaded and the notes saved. To keep this fix from disappearing, DB_SSL = "true" and the firewall rule belong in main.tf as well.
Add screenshots of the container log error and of the fix if you have them:
�
Load image
�
Load image
Keeping secrets safe
The .gitignore file includes the Terraform folder, the state files, any variable files, and the downloaded log folders, because these can hold passwords:
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
logs.zip
applogs/
Before the first push I ran git ls-files to confirm that no state file had been committed. The .terraform.lock.hcl file stays in the repository on purpose.
Cleaning up
The App Service plan and the PostgreSQL server cost money while they run, so I destroy everything once I have my screenshots:
terraform destroy --auto-approve
Creating the infrastructure again gives new random suffixes. After that I update the ACR_NAME and WEBAPP_NAME secrets with the new values.
Add a screenshot of the destroy finishing:
�
Load image
What I learned
A service principal should get the smallest role and the smallest scope that still works.
A secret with a trailing space looks fine on screen and still breaks everything.
A green pipeline only proves the deployment step ran. The container logs show whether the app is healthy.
Platform services like Azure PostgreSQL expect encrypted connections, and the app has to be told to use them.
Anything I fix by hand in the portal or the CLI should be written back into Terraform, or the next apply will undo it.
Reading the exact error line, slowly, solves most problems faster than guessing.
