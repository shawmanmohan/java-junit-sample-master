pipeline {

    agent {
      label 'master'
    }

    environment {
        /* Per app configured variables... */
        dockerRegistry = 'docker.registry.com'
        gitRepo = 'https://github.com/stutirastogi/java-devops.git'
        dockerRepo = 'java-junit-sample'
    }

    options {
        timestamps()
        ansiColor(colorMapName: 'xterm')
    }

    stages {

        stage('Build') {
            steps {
                lock(resource: env.JOB_NAME + "-Build", inversePrecedence: true) {
                    sh 'mvn -B -U clean install -f pom.xml'
                    junit allowEmptyResults: true, testResults: '**/target/**/TEST*.xml'
                    script {
                        gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        try {
                        sh "sudo docker build --rm -t ${dockerRepo} ."
                        } catch (ex) {
                           error "Error when building docker image"
                        }
                    }
                }
            }
        }

        stage('Analysis') {
            steps {
                lock(resource: env.JOB_NAME + "-Analysis", inversePrecedence: true) {
                    echo 'Starting Sonar Analysis'
                    sh 'mvn cobertura:cobertura -Dcobertura.report.format=xml -f pom.xml'
                    sh 'mvn sonar:sonar -Psonar -f pom.xml'
                }
            }
        }

        stage('Publish') {
            steps {
                lock(resource: env.JOB_NAME + "-docker-publish", inversePrecedence: true) {
                    script {
                        try {
                            echo "Pushing docker image to Registry"
                            sh "sudo docker tag -f ${dockerRepo}:${gitCommit} ${dockerRegistry}/${dockerRepo}:${gitCommit} || true"
                            sh "sudo docker push ${dockerRegistry}/${dockerRepo}:${gitCommit}"
                            echo "Cleaning up docker images after successful push"
                            sh "sudo docker rmi -f ${dockerRegistry}/${dockerRepo}:${gitCommit}"
                            sh "sudo docker rmi -f ${dockerRepo}:${gitCommit}"
                        } catch (ex) {
                            echo 'Cleaning up docker images after failure'
                            sh "sudo docker rmi -f ${dockerRegistry}/${appName}:${gitCommit} || true"
                            sh "sudo docker rmi -f ${dockerRepo}:${gitCommit} || true"
                            error("Error pushing docker image to repository")
                        }
                    }
                }
            }
        }

        stage('Clean-Previous-Deploy') {
            steps {
                lock(resource: env.JOB_NAME + "-deploy", inversePrecedence: true) {
                    sh returnStdout: true, script: '''sudo docker ps -q -f name=${dockerRepo}
                            if [ $? -eq 1 ]; then
                                sudo docker stop ${dockerRepo}
                            elif 
                               echo "No Container Found"
                            fi'''
                    }
            }
        }

        stage('Deploy') {
            agent {
                label 'dev.naggaro.com'
            }
            steps {
                lock(resource: env.JOB_NAME + "-deploy", inversePrecedence: true) {
                  sh returnStdout: true, script: '''sudo docker ps -aq -f status=exited -f name=${dockerRepo}
                            if [ $? -eq 1 ]; then
                                sudo docker rm ${dockerRepo}
                            elif 
                               echo "No Container Found, Starting New"
                               sudo docker run -it -d -p 8080:8080 --name=${dockerRepo} --restart=unless-stopped ${dockerRegistry}/${dockerRepo}:${gitCommit}
                            fi
                           '''
                }
            }
        }

        stage('Deploy-Sanity') {
            steps {
                lock(resource: env.JOB_NAME + "-smoke-test", inversePrecedence: true) {
                echo 'Starting Smoke Test'
                sh "mvn clean verify"
            }
            }
        }
        
    }
    
    post {
      /* Steps to run after the pipeline is complete */
      success {
          emailext(
              to: 'stutirastogi92@gmail.com',
              subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
          body: '<p>Check console output at <a href=${BLUE_OCEAN_URL}>${JOB_NAME} [${BUILD_NUMBER}]</a></p>'
        )
        }
      failure {
          emailext(
              to: 'stutirastogi92@gmail.com',
              subject: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
              body: '<p>Check console output at <a href=${BLUE_OCEAN_URL}>${JOB_NAME} [${BUILD_NUMBER}]</a></p>'
          )
      }
    }
}
