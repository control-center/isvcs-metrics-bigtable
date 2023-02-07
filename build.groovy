pipeline {

    agent {
        label 'docker-centos-7-4'
    }

    stages {
        stage('Build Image'){
            steps {
                script {
                    otsdbimage = docker.build("zenoss/isvcs-metrics-bigtable:v2-dev")
                }
            }
        }
        stage('Push Image'){
            steps {
                script {
                    otsdbimage.push()
                }
            }
        }
    }
}
