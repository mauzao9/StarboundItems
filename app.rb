require 'sinatra'
require 'sinatra/content_for'
require 'grape'
require 'elasticsearch'
require 'redis'

Redis.current = Redis.new(url: ENV['REDISCLOUD_URL'])

class API < Grape::API
  format :json
  prefix :api

  desc "Search for an item"
  params do
    requires :query, type: String, desc: "Search query"
  end
  get :search do
    clean_query = params[:query].gsub(/[^0-9a-z ]/i, '')

    search = elasticsearch.search(
      index: 'starbound',
      type:  'item',
      q:     "*#{clean_query}*",
      size:  100,
      sort:  'itemName')

    search['hits']['hits'].map do |k, _v|
      {
        itemName:         k['_source']['itemName'],
        shortdescription: k['_source']['shortdescription'],
        description:      k['_source']['description'],
        inventoryIcon:    k['_source']['inventoryIcon'],
        type:             k['_source']['type'],
        rarity:           k['_source']['rarity']
      }
    end
  end

  desc "List items"
  params do
    optional :page, type: Integer, desc: "Page Number"
  end
  get :items do
    total_items = total_item_count
    current_page = params[:page].to_i

    if current_page == 0 || current_page == 1
      count = 0
    else
      count = (current_page * 200) - 200
    end

    elasticsearch.search(
      index: 'starbound',
      type: 'item',
      size: 200,
      from: count,
      sort: 'itemName')['hits']['hits'].map do |k, _v|
        {
          itemName:         k['_source']['itemName'],
          shortdescription: k['_source']['shortdescription'],
          description:      k['_source']['description'],
          inventoryIcon:    k['_source']['inventoryIcon'],
          type:             k['_source']['type'],
          rarity:           k['_source']['rarity']
        }
      end
  end

  desc "Get single item"
  params do
    requires :id, type: Integer, desc: "Item ID"
  end
  get :item do
    elasticsearch.get(
      index: 'starbound',
      type:  'item',
      id:    params[:id]
    )['_source']
  end

  desc "Get search stats"
  get :stats do
    total_searches = format_number(redis.get('searches'))
    stable_item_count = format_number(total_item_count)

    searches = redis.zrevrange('search_terms', 0, 9, with_scores: true).map do |v|
      {
        term:  v.first,
        score: format('%.0f', v.last)
      }
    end

    {total_searches: total_searches,
     item_count: stable_item_count,
     search_terms: searches}
  end

end

class Web < Sinatra::Base
  helpers Sinatra::ContentFor

  get '/' do
    erb :index
  end
end

private

  def format_number(num)
    # Is this seriously the only way?
    num.to_s.reverse.gsub(/...(?=.)/, '\&,').reverse
  end

  def total_item_count
    elasticsearch.indices.stats['_all']['primaries']['docs']['count'].to_i
  end

  def redis
    Redis.current
  end

  def elasticsearch
    Elasticsearch::Client.new host: ENV['BONSAI_URL']
  end
