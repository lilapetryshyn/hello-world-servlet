pipeline {
  agent any
  stages {
    stage("Build project") {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/docker']],
                                    doGenerateSubmoduleConfigurations: false,
                                    extensions: [],
                                    submoduleCfg: [],
                                    userRemoteConfigs: [[credentialsId: 'git-ssh',
                                    url: 'https://github.com/lilapetryshyn/hello-world-servlet.git']]])
        script {
          withMaven(maven: 'maven-3.5.4') {
            sh "mvn clean install -Dv=${env.BUILD_NUMBER}"
          }
        }
      }
    }
    stage("Docker build") {
      steps {
        script {
          def testImage = docker.build("test-tomcat")
        }
      }
    }
    stage('Run container') {
      steps {
        script {
          sh "docker run -d -p 8000:8000 test-tomcat"
        }
      }
    }
  }
}
