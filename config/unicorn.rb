# config/unicorn.rb
worker_processes 2
working_directory '/home/ubuntu/some/log_api'
#working_directory  '\\wsl$\Ubuntu-22.04\home\steel\nawe\firebase\vol4\app_named_poly'
listen '/tmp/unicorn.sock', backlog: 64
timeout 30