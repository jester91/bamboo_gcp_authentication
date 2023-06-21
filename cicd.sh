#!/bin/bash
# Download and extract Google Cloud SDK
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-434.0.0-linux-x86_64.tar.gz
tar -xf google-cloud-cli-434.0.0-linux-x86_64.tar.gz
# Check Docker version
docker --version
# Create a keyfile.json with service account credentials
echo '{
  "type": ${bamboo.type},
  "project_id": ${bamboo.project_id_dev},
  "private_key_id": ${bamboo.private_key_id_dev},
  "private_key": ${bamboo.private_key_dev},
  "client_email": ${bamboo.client_email_dev},
  "client_id": ${bamboo.client_id_dev},
  "auth_uri": ${bamboo.auth_uri},
  "token_uri": ${bamboo.token_uri},
  "auth_provider_x509_cert_url": ${bamboo.auth_provider_x509_cert_url},
  "client_x509_cert_url": ${bamboo.client_x509_cert_url_dev},
  "universe_domain": ${bamboo.universe_domain}
}' > ./keyfile.json

# Display the contents of keyfile.json
cat ./keyfile.json
# Install Google Cloud SDK
./google-cloud-sdk/install.sh --quiet
# Install docker-credential-gcr component
./google-cloud-sdk/bin/gcloud components install docker-credential-gcr --quiet
# Create a symbolic link for docker-credential-gcr
ln -s ./google-cloud-sdk/bin/docker-credential-gcr /usr/local/bin/
# Set up environment variables
pwddata=`pwd`
export PATH=$PATH:$pwddata/google-cloud-sdk/bin
export GOOGLE_APPLICATION_CREDENTIALS=$pwddata/keyfile.json
# Authenticate with the service account
./google-cloud-sdk/bin/gcloud auth activate-service-account ${bamboo.client_email_dev} --key-file=$pwddata/keyfile.json
# Configure Docker with the appropriate registry
./google-cloud-sdk/bin/gcloud auth configure-docker us-central1-docker.pkg.dev
# Push the Docker image to the Container Registry
cd services/client
docker push us-central1-docker.pkg.dev/containerregistry/container/image:latest
# Move back to the root directory
cd .. && cd ..

# Deploy the image to Cloud Run
./google-cloud-sdk/bin/gcloud run deploy cloud_run_name --image=us-central1-docker.pkg.dev/containerregistry/container/image:latest --platform managed --project projectname --region us-central1