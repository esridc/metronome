module Metrics
  ELASTICSEARCH = Elasticsearch::Client.new log: true
  def metrics(query)
    index = "logstash-#{Time.now.strftime("%Y.%m")}"

    h = {query: {match: {query.keys.first => {query: query.values.first, type: "phrase"}}}}
    h[:aggs] = { 
      accept: {terms: {field: "accept" }}, 
      view_history: {date_histogram: {field: "@timestamp", interval: "minute"}},
      referer: {terms: { field: "referer" }}}
    
    puts "Query: #{h}"
    resp = ELASTICSEARCH.search  index: index, body: h
    
    puts "Response: #{resp.inspect}"
    {history: resp['aggregations']['view_history']['buckets'].inject({}) {|s,b| s[b['key_as_string']] = b['doc_count']; s},
      downloads: resp['aggregations']['accept']['buckets'].inject({}) {|s,b| s[b['key']] = b['doc_count']; s},
      referers: resp['aggregations']['referer']['buckets'].inject({}) {|s,b| s[b['key']] = b['doc_count']; s}}
  end

  def downloads
    self.usage[:downloads].inject(0) {|s,k| s += k[1] unless k[0] =~ /html|json|javascript/;s}
  end
  def views
    self.usage[:downloads].inject(0) {|s,k| s += k[1] if k[0] =~ /html/;s}
  end
end
