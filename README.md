Overview
===
Library for interacting with the SmugMug 1.3.0 API using OAuth authentication. This does not do any OAuth authorization or setup, it's assumed you're using another gem such as omniauth-oauth that handles that part.

Compability
-
Tested against Ruby 1.8.7, 1.9.2, 2.0.0 and JRuby, build history is available [here](http://travis-ci.org/zanker/ruby-smugmug).

<img src="https://secure.travis-ci.org/zanker/ruby-smugmug.png?branch=master&.png"/>

Examples
-
This is just a thin wrapper around the [SmugMug 1.3.0 API](http://wiki.smugmug.net/display/API/API+1.3.0), it's a 1:1 wrapper, so all of the documentation on the SmugMug page applies to this library.

    client = SmugMug::Client.new(:api_key => "1234-api", :oauth_secret => "4321-secret", :user => {:token => "abcd-token", :secret => "abcd-secret"})

    data = client.users.getStats(:Month => 2, :Year => 2012)
    puts data # {"Bytes"=>0, "Hits"=>0, "Large"=>0, "Medium"=>0, "Small"=>0, "Video110"=>0, "Video200"=>0, "Video320"=>0, "Video640"=>0, "X2Large"=>0, "X3Large"=>0, "XLarge"=>0}

    data = client.styles.getTemplates
    puts data # [{"id"=>0, "Name"=>"Viewer Controlled"}, {"id"=>3, "Name"=>"SmugMug"}, {"id"=>4, "Name"=>"Traditional"}, {"id"=>7, "Name"=>"All Thumbs"}, {"id"=>8, "Name"=>"Slideshow"}, {"id"=>9, "Name"=>"Journal (Old)"}, {"id"=>10, "Name"=>"SmugMug Small"}, {"id"=>11, "Name"=>"Filmstrip"}, {"id"=>12, "Name"=>"Critique"}, {"id"=>16, "Name"=>"Journal"}, {"id"=>17, "Name"=>"Thumbnails"}]

You can use any arguments that the SmugMug 1.3.0 documentation shows under the OAuth option.



Documentation
-
See http://rubydoc.info/github/zanker/ruby-smugmug/master/frames for full documentation.

License
-
Available under the MIT license, see LICENSE for more information.