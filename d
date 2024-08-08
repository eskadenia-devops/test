# Change to the directory of your project
cd 'C:\Users\i.docker\source\Workspaces\Medical\Claims';

# Get the latest code from the repository
& 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe' get . /recursive

# Function to increment the version
function Increment-Version {
    param (
        [string]$version
    )
    $parts = $version -split '\.'
    if ($parts[2] -eq 9) {
        $parts[2] = 0
        $parts[1] = [int]$parts[1] + 1
    } else {
        $parts[2] = [int]$parts[2] + 1
    }
    return "$($parts[0]).$($parts[1]).$($parts[2])"
}

# Replace these variables with your Docker Hub repository details
$DOCKER_USER = "eskadeniadocker"
$DOCKER_REPO = "medical"
$FILTER_WORD = "claims-v"
$DOCKER_PASSWORD = "your_dockerhub_password"  # Replace with your Docker Hub password

# Docker Hub authentication
docker login -u $DOCKER_USER -p $DOCKER_PASSWORD

# Fetch all tags from Docker Hub API
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$DOCKER_USER:$DOCKER_PASSWORD"))
}

$tags = Invoke-RestMethod -Uri "https://hub.docker.com/v2/repositories/$DOCKER_USER/$DOCKER_REPO/tags/?page_size=100" -Headers $headers | 
        Select-Object -ExpandProperty results | 
        Where-Object { $_.name -like "*$FILTER_WORD*" } | 
        Select-Object -ExpandProperty name

# Find the latest tag that contains the word
$latest_tag = Invoke-RestMethod -Uri "https://hub.docker.com/v2/repositories/$DOCKER_USER/$DOCKER_REPO/tags/?page_size=100" -Headers $headers | 
              Select-Object -ExpandProperty results | 
              Sort-Object -Property last_updated -Descending | 
              Where-Object { $_.name -like "*$FILTER_WORD*" } | 
              Select-Object -First 1 -ExpandProperty name

# If no tags found, start with 1.0.0
if (-not $latest_tag) {
    $next_tag = "claims-v1.0.0"
} else {
    # Increment the latest tag version
    $next_tag = Increment-Version -version $latest_tag
}

# Print the next tag version
Write-Output "$next_tag"

# Change to the project directory
cd 'C:\Users\i.docker\source\Workspaces\Medical\Claims';

# Build and push the Docker image
docker build -t eskadeniadocker/medical:"$next_tag" . -f 'C:\Users\i.docker\source\Workspaces\Medical\Claims\API\Dockerfile'
docker push eskadeniadocker/medical:"$next_tag"
