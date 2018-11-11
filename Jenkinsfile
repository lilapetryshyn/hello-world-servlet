String ARTIFACTORY_URL = 'http://192.168.10.55:8081/artifactory'
pipeline {
  agent any
  stages {
    stage("Create instance") {
      steps {
        script {
          sh '''aws ec2 run-instances --image-id ami-6cd6f714 --count 1 --instance-type t2.micro --key-name ec2 --security-groups TomcatSG > instance.json'''
          INSTANCE_ID = sh(returnStdout: true, script: '''cat instance.json | grep -iw InstanceId | cut -d'"' -f4 | tail -1''')
          println "${INSTANCE_ID}"
          String FILTER = "Name=instance-id, Values=${INSTANCE_ID}"
          echo "Waiting before instance will running"
          sh "aws ec2 wait instance-running --filters '${FILTER}'"
          env.INSTANCE_IP = sh(returnStdout: true, script: """aws ec2 describe-instances --filters '${FILTER}' | grep -iw PublicIP | cut -d'"' -f4 | tail -1""")
        }
      }
    }
    stage("Build project") {
      steps {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']],
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
    stage("Deploy to artifactory") {
      steps {
        script {
          def server = Artifactory.newServer url: "${ARTIFACTORY_URL}", credentialsId: 'artifactory-deploy-user'
          def uploadSpec = """{
            "files": [
              {
                "pattern": "${env.WORKSPACE}/target/helloworld/*",
                "target": "generic-local"
              }
            ]
          }"""
          server.upload(uploadSpec)
        }
        sh "echo 'deploying'"
      }
    }
    stage("Ansible-tomcat") {
      steps {
        println env.INSTANCE_IP
        checkout([$class: 'GitSCM', branches: [[name: '*/master']],
                                    doGenerateSubmoduleConfigurations: false,
                                    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'tomcat-ansible']],
                                    submoduleCfg: [],
                                    userRemoteConfigs: [[credentialsId: 'git-ssh',
                                    url: 'https://github.com/lilapetryshyn/tomcat-ansible.git']]])
        ansiblePlaybook become: true, credentialsId: 'ec2-ssh', disableHostKeyChecking: true, inventory: 'tomcat-ansible/hosts', playbook: 'tomcat-ansible/site.yml'
      }
    }
  }
  post {
    success {
      sshagent(['ec2-ssh']) {
        sh "scp -o StrictHostKeyChecking=no target/*.war 'ec2-user@${env.INSTANCE_IP}:/tmp'"
        sh "ssh -o StrictHostKeyChecking=no ec2-user@${env.INSTANCE_IP} 'sudo mv /tmp/*.war /opt/tomcat/webapps/'"
      }
    }
  }
}
