# Run `kill -TTIN {pid}` to get backtraces for a running process
trap "TTIN" do
  Thread.list.each do |thread|
    puts "Thread TID-#{thread.object_id.to_s(36)}"
    puts thread.backtrace.join("n")
  end
end
