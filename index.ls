require! \azure
require! uuid: \node-uuid
{ EventEmitter } = require \events
{ is-type } = require \prelude-ls

module.exports.merge = merge = (dest, src, prefix) ->
  for key, value of src
    dest["#{prefix}_#{key}"] = value
  return dest

module.exports.flatten = flatten = (entity) ->
  merged = false
  for key, value of entity
    entity[key] = '' if not value?
    if is-type \Object, value
      merge entity, value, key
      delete entity[key]
      merged = true
  flatten entity if merged
  return entity

module.exports.AzureStream = class AzureStream extends EventEmitter
  ({account, access_key, @table} = {}) ->
    @client = azure.createTableService account, access_key
    @client.createTableIfNotExists @table, (err) ~> @emit \error, that if err?
    @writable = true

    EventEmitter.call(this)

  write: (record, encoding, done) ->
    throw new Error 'AzureStream not writable' if not @writable

    record = JSON.parse record
    entity = { RowKey: uuid.v4!, PartitionKey: record.name } <<< record

    @client.insertEntity @table, entity, (err) ~>
      @emit \error, that if err?
      done?!

  end: ->
    @writable = false

  destroy: ->
    @writable = false
    @emit \close

  destroySoon: -> @destroy!
