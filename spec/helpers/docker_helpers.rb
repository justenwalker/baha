module DockerHelpers
  require 'docker'
  def mock_registry(images)
    allow(Docker::Image).to receive(:create).and_raise(RuntimeError)  
    allow(Docker::Image).to receive(:get).and_raise(RuntimeError)  
    images.each do |image|
      i = double("image-#{image[:id]}")
      allow(i).to receive(:id) { image[:id] }
      allow(i).to receive(:info) do
        { 'Parent' => image[:parent] }
      end
      allow(i).to receive(:history) do
        [{'Tags' => image[:tags] }]
      end
      name = "#{image[:name]}:#{image[:tag]}"
      if image[:pulled]
        allow(Docker::Image).to receive(:get).with(name).and_return(i)
      else
        allow(Docker::Image).to receive(:get).with(name).and_raise(RuntimeError)
        allow(Docker::Image).to receive(:create).with('fromImage'=>image[:name], 'tag' =>image[:tag]).and_raise(RuntimeError)
      end
      allow(Docker::Image).to receive(:get).with(image[:id]).and_return(i)
      if image[:tags]
        image[:tags].each do |tag|
          t = tag.split(':')
          allow(Docker::Image).to receive(:create).with('fromImage'=>t[0], 'tag' =>t[1]).and_return(i)
        end
      end
    end
  end
end