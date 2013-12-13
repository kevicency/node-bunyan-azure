require! \chai
require! \sinon
require! \sinon-chai

expect = chai.expect
_it = it
chai.use sinon-chai

require! \azure
{ AzureStream, flatten, merge } = require './index'

createDefaultStream = -> new AzureStream account: \user, access_key: \secret, table: \logs

describe \flatten ->
  _it 'replaces nulls with empty string' ->
    expect flatten foo: void .to.have.property \foo, ''
  _it 'merges complex properties' ->
    expect flatten foo: bar: \baz .to.have.property \foo_bar, \baz
  _it 'removes complex property after merge' ->
    expect flatten foo: bar: \baz .to.not.have.property \foo
  _it 'works with complex object' ->
    obj =
      foo: 1
      bar: void
      baz:
        qux: 'quux'
        gorge: void
      very:
        deeply:
          nested: 'idd'
    expected =
      foo: 1
      bar: ''
      baz_qux: 'quux'
      baz_gorge: ''
      very_deeply_nested: 'idd'

    expect flatten obj .to.be.eql expected


describe \AzureStream ->
  var client

  beforeEach ->
    client :=
      createTableIfNotExists: ->
      insertEntity: ->
    sinon.stub azure, \createTableService .returns client

  afterEach -> azure.createTableService.restore!

  _it 'is defined' ->
    expect AzureStream .to.not.be.undefined

  describe '.ctor(options:{account, access_key})' ->
    _it 'creates azure client with account and access_key' ->
      sut = new AzureStream account: \user, access_key: \secret

      expect azure.createTableService .to.have.been
        .calledOnce.and.calledWith \user, \secret
      expect sut.client .to.be.equal client

    _it 'ensures table' ->
      sinon.spy client, \createTableIfNotExists
      sut = new AzureStream table: \foo

      expect client.createTableIfNotExists .to.have.been.calledWith \foo

  describe '#write(record)' ->
    var sut
    beforeEach ->
      sut := createDefaultStream!
      sinon.spy client, \insertEntity

    _it 'writes the record to the correct table' ->
      sut.write "{}"

      expect client.insertEntity .to.have.been.calledOnce.and.calledWith \logs

    _it 'adds RowKey and PartitionKey to the record' ->
      record = JSON.stringify name: \foo

      sut.write record

      expect client.insertEntity .to.have.been.calledOnce.and.calledWithMatch sinon.match.string,
        RowKey: sinon.match /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/ #uuid
        PartitionKey: \foo

    _it 'throws error when not wirtable' ->
      sut.writable = false

      expect (-> sut.write!) .to.throw Error, /not writable/

  describe '#end' ->
    var sut
    beforeEach -> sut := createDefaultStream!

    _it 'sets the stream to not writable' ->
      sut.end!

      expect sut.writable .to.be.false

  describe '#destroy' ->
    var sut
    beforeEach -> sut := createDefaultStream!

    _it 'sets the stream to not writable' ->
      sut.destroy!

      expect sut.writable .to.be.false

    _it 'emits \'close\'' (done) ->
      sut.on \close, -> done!
      sut.destroy!
