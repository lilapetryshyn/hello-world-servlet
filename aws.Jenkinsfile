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
          env.INSTANCE_IP = sh(returnStdout: true, script: """aws ec2 describe-instances --filters '${FILTER}' | grep -iw PublicIP | cut -d'"' -f4 | tail -1""").toString().replaceAll('\n', '')
        }
      }
    }
    stage("Ansible-tomcat") {
      steps {
        println env.INSTANCE_IP
        checkout([$class: 'GitSCM', branches: [[name: '*/docker']],
                               doGenerateSubmoduleConfigurations: false,
                               extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'tomcat-ansible']],
                               submoduleCfg: [],
                               userRemoteConfigs: [[credentialsId: 'git-ssh',
                               url: 'https://github.com/lilapetryshyn/tomcat-ansible.git']]])
        ansiblePlaybook become: true, credentialsId: 'ec2-ssh', disableHostKeyChecking: true, inventory: 'tomcat-ansible/hosts', playbook: 'tomcat-ansible/docker.yml'
      }
    }
  }
}
