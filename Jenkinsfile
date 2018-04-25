pipeline {
  agent none
  stages {

    stage('Style Check') {
      agent {
        docker { image 'px4io/px4-dev-base:2018-03-30' }
      }

      steps {
        sh 'make check_format'
      }
    }

    stage('Build') {
      steps {
        script {
          def builds = [:]

          def docker_base = "px4io/px4-dev-base:2018-03-30"
          def docker_nuttx = "px4io/px4-dev-nuttx:2018-03-30"
          def docker_ros = "px4io/px4-dev-ros:2018-03-30"
          def docker_rpi = "px4io/px4-dev-raspi:2018-03-30"
          def docker_armhf = "px4io/px4-dev-armhf:2017-12-30"
          def docker_arch = "px4io/px4-dev-base-archlinux:2018-03-30"
          def docker_snapdragon = "lorenzmeier/px4-dev-snapdragon:2017-12-29"
          def docker_clang = "px4io/px4-dev-clang:2018-03-30"

          // posix_sitl_default with package
          builds["sitl"] = {
            node {
              stage("Build Test sitl") {
                docker.image(docker_ros).inside('-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw') {
                  stage("sitl") {
                    checkout scm
                    sh "export"
                    sh "make distclean"
                    sh "ccache -z"
                    sh "make posix_sitl_default"
                    sh "ccache -s"
                    sh "make posix_sitl_default sitl_gazebo"
                    sh "make posix_sitl_default package"
                    stash name: "px4_sitl_package", includes: "build/posix_sitl_default/*.zip"
                    sh "make distclean"
                  }
                }
              }
            }
          }

          parallel builds
        } // script
      } // steps
    } // stage Builds

    stage('Test') {
      parallel {

        stage('clang analyzer') {
          agent {
            docker {
              image 'px4io/px4-dev-clang:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean'
            sh 'make scan-build'
            // publish html
            publishHTML target: [
              reportTitles: 'clang static analyzer',
              allowMissing: false,
              alwaysLinkToLastBuild: true,
              keepAll: true,
              reportDir: 'build/scan-build/report_latest',
              reportFiles: '*',
              reportName: 'Clang Static Analyzer'
            ]
            sh 'make distclean'
          }
          when {
            anyOf {
              branch 'master'
              branch 'beta'
              branch 'stable'
            }
          }
        }

        stage('clang tidy') {
          agent {
            docker {
              image 'px4io/px4-dev-clang:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean'
            sh 'make clang-tidy-quiet'
            sh 'make distclean'
          }
        }

        stage('cppcheck') {
          agent {
            docker {
              image 'px4io/px4-dev-base:ubuntu17.10'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean'
            sh 'make cppcheck'
            // publish html
            publishHTML target: [
              reportTitles: 'Cppcheck',
              allowMissing: false,
              alwaysLinkToLastBuild: true,
              keepAll: true,
              reportDir: 'build/cppcheck/',
              reportFiles: '*',
              reportName: 'Cppcheck'
            ]
            sh 'make distclean'
          }
          when {
            anyOf {
              branch 'master'
              branch 'beta'
              branch 'stable'
            }
          }
        }

        stage('tests') {
          agent {
            docker {
              image 'px4io/px4-dev-base:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean'
            sh 'make posix_sitl_default test_results_junit'
            junit 'build/posix_sitl_default/JUnitTestResults.xml'
            sh 'make distclean'
          }
        }

        stage('check stack') {
          agent {
            docker {
              image 'px4io/px4-dev-nuttx:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean'
            sh 'make px4fmu-v2_default stack_check'
            sh 'make distclean'
          }
        }

        stage('ROS vtol mission new 1') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_test_mission.test mission:=vtol_new_1 vehicle:=standard_vtol'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

        stage('ROS vtol mission new 2') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_test_mission.test mission:=vtol_new_2 vehicle:=standard_vtol'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

        stage('ROS vtol mission old 1') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_test_mission.test mission:=vtol_old_1 vehicle:=standard_vtol'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

        stage('ROS vtol mission old 2') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_test_mission.test mission:=vtol_old_2 vehicle:=standard_vtol'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

        stage('ROS MC mission box') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_test_mission.test mission:=multirotor_box vehicle:=iris'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

        stage('ROS offboard att') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_tests_offboard_attctl.test'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

        stage('ROS offboard pos') {
          agent {
            docker {
              image 'px4io/px4-dev-ros:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw -e HOME=$WORKSPACE'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean; rm -rf .ros; rm -rf .gazebo'
            sh 'git fetch --tags'
            sh 'make posix_sitl_default'
            sh 'make posix_sitl_default sitl_gazebo'
            sh './test/rostest_px4_run.sh mavros_posix_tests_offboard_posctl.test'
            sh './Tools/ecl_ekf/process_logdata_ekf.py `find . -name *.ulg -print -quit`'
          }
          post {
            always {
              sh './Tools/upload_log.py -q --description "${JOB_NAME}: ${STAGE_NAME}" --feedback "${JOB_NAME} ${CHANGE_TITLE} ${CHANGE_URL}" --source CI .ros/rootfs/fs/microsd/log/*/*.ulg'
              archiveArtifacts '.ros/**/*.pdf'
              archiveArtifacts '.ros/**/*.csv'
              sh 'make distclean'
            }
            failure {
              archiveArtifacts '.ros/**/*.ulg'
              archiveArtifacts '.ros/**/rosunit-*.xml'
              archiveArtifacts '.ros/**/rostest-*.log'
            }
          }
        }

      }
    }

    stage('Generate Metadata') {

      parallel {

        stage('airframe') {
          agent {
            docker { image 'px4io/px4-dev-base:2018-03-30' }
          }
          steps {
            sh 'make distclean'
            sh 'make airframe_metadata'
            archiveArtifacts(artifacts: 'airframes.md, airframes.xml', fingerprint: true)
            sh 'make distclean'
          }
        }

        stage('parameter') {
          agent {
            docker { image 'px4io/px4-dev-base:2018-03-30' }
          }
          steps {
            sh 'make distclean'
            sh 'make parameters_metadata'
            archiveArtifacts(artifacts: 'parameters.md, parameters.xml', fingerprint: true)
            sh 'make distclean'
          }
        }

        stage('module') {
          agent {
            docker { image 'px4io/px4-dev-base:2018-03-30' }
          }
          steps {
            sh 'make distclean'
            sh 'make module_documentation'
            archiveArtifacts(artifacts: 'modules/*.md', fingerprint: true)
            sh 'make distclean'
          }
        }

        stage('uorb graphs') {
          agent {
            docker {
              image 'px4io/px4-dev-nuttx:2018-03-30'
              args '-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw'
            }
          }
          steps {
            sh 'export'
            sh 'make distclean'
            sh 'make uorb_graphs'
            archiveArtifacts(artifacts: 'Tools/uorb_graph/graph_sitl.json')
            sh 'make distclean'
          }
        }
      }
    }

    stage('S3 Upload') {
      agent {
        docker { image 'px4io/px4-dev-base:2018-03-30' }
      }

      when {
        anyOf {
          branch 'master'
          branch 'beta'
          branch 'stable'
        }
      }

      steps {
        sh 'echo "uploading to S3"'
      }
    }
  } // stages

  environment {
    CCACHE_DIR = '/tmp/ccache'
    CI = true
  }
  options {
    buildDiscarder(logRotator(numToKeepStr: '10', artifactDaysToKeepStr: '30'))
    timeout(time: 60, unit: 'MINUTES')
  }
}

def createBuildNode(String docker_repo, String target) {
  return {
    node {
      docker.image(docker_repo).inside('-e CCACHE_BASEDIR=${WORKSPACE} -v ${CCACHE_DIR}:${CCACHE_DIR}:rw') {
        stage(target) {
          sh('export')
          checkout scm
          sh('make distclean')
          sh('git fetch --tags')
          sh('ccache -z')
          sh('make ' + target)
          sh('ccache -s')
          sh('make sizes')
          archiveArtifacts(allowEmptyArchive: true, artifacts: 'build/**/*.px4, build/**/*.elf', fingerprint: true, onlyIfSuccessful: true)
          sh('make distclean')
        }
      }
    }
  }
}

def createBuildNodeDockerLogin(String docker_repo, String docker_credentials, String target) {
  return {
    node {
      docker.withRegistry('https://registry.hub.docker.com', docker_credentials) {
        docker.image(docker_repo).inside('-e CCACHE_BASEDIR=$WORKSPACE -v ${CCACHE_DIR}:${CCACHE_DIR}:rw') {
          stage(target) {
            sh('export')
            checkout scm
            sh('make distclean')
            sh('git fetch --tags')
            sh('ccache -z')
            sh('make ' + target)
            sh('ccache -s')
            sh('make sizes')
            archiveArtifacts(allowEmptyArchive: true, artifacts: 'build/**/*.px4, build/**/*.elf', fingerprint: true, onlyIfSuccessful: true)
            sh('make distclean')
          }
        }
      }
    }
  }
}
