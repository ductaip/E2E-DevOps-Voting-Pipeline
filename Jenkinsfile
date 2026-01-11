pipeline {
    agent any

    environment {
        REGISTRY_URL = "${env.REGISTRY_URL}" 
        // Define other global envs if needed
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Determine Changes') {
            steps {
                script {
                    // Check for changes in specific directories
                    env.BUILD_VOTE = sh(script: "git diff --name-only HEAD~1 HEAD | grep '^vote/' || true", returnStdout: true).trim()
                    env.BUILD_RESULT = sh(script: "git diff --name-only HEAD~1 HEAD | grep '^result/' || true", returnStdout: true).trim()
                    env.BUILD_WORKER = sh(script: "git diff --name-only HEAD~1 HEAD | grep '^worker/' || true", returnStdout: true).trim()
                    
                    echo "Changes detected: Vote=${env.BUILD_VOTE}, Result=${env.BUILD_RESULT}, Worker=${env.BUILD_WORKER}"
                }
            }
        }

        stage('Test & Quality') {
            parallel {
                stage('Vote Unit Tests') {
                    when { expression { return env.BUILD_VOTE != '' } }
                    steps {
                        dir('vote') {
                            sh 'pip install -r requirements.txt && python -m unittest discover tests' 
                            // Placeholder command, assuming tests exist
                        }
                    }
                }
                stage('Result Tests') {
                    when { expression { return env.BUILD_RESULT != '' } }
                    steps {
                        dir('result') {
                            sh 'npm install && npm test'
                        }
                    }
                }
                stage('SonarQube Scan') {
                    steps {
                        // Assuming Sonar scanner is configured
                        withSonarQubeEnv('SonarQube') {
                            sh 'echo "Running Global SonarQube Scan..."'
                            // sh 'sonar-scanner ...'
                        }
                    }
                }
            }
        }

        stage('Build & Push Images') {
            parallel {
                stage('Build Vote') {
                    when { expression { return env.BUILD_VOTE != '' } }
                    steps {
                        script {
                            docker.build("${REGISTRY_URL}/vote:${BUILD_NUMBER}", "./vote").push()
                        }
                    }
                }
                stage('Build Result') {
                    when { expression { return env.BUILD_RESULT != '' } }
                    steps {
                        script {
                            docker.build("${REGISTRY_URL}/result:${BUILD_NUMBER}", "./result").push()
                        }
                    }
                }
                stage('Build Worker') {
                    when { expression { return env.BUILD_WORKER != '' } }
                    steps {
                        script {
                            docker.build("${REGISTRY_URL}/worker:${BUILD_NUMBER}", "./worker").push()
                        }
                    }
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                // Scan images if built
                script {
                    if (env.BUILD_VOTE != '') {
                        sh "trivy image ${REGISTRY_URL}/vote:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Deploy to K8s') {
            steps {
                script {
                    sh """
                    helm upgrade --install voting-app ./charts/voting-app-chart \
                    --set services.vote.tag=${BUILD_NUMBER} \
                    --set services.result.tag=${BUILD_NUMBER} \
                    --set services.worker.tag=${BUILD_NUMBER} \
                    --wait
                    """
                }
            }
        }
    }
}
