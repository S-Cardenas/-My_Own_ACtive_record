require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns

    @out ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    cols = @out[0].map {|el| el.to_sym}
    # ...
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      setter = (col.to_s + :'='.to_s).to_sym
      define_method(setter) do |arg|
        self.attributes[col] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
    # ...
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
    # ...
  end

  def self.all
    elements ||= DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL


    self.parse_all(elements)

  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    self.all.find {|obj| obj.id == id}
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, value|
      attr_name = attr_name.to_s
      raise "unknown attribute '#{attr_name}'" if !self.class.columns.include?(attr_name.to_sym)
      self.send(attr_name + '=', value)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    arr = self.class.columns
    arr.map { |el| self.send(el) }
  end

  def insert
    n = self.class.columns.length
    question_marks = ['?'] * n
    question_marks = question_marks.join(',')
    col_names =  self.class.columns.map { |el| el.to_s }
    col_names = col_names.join(',')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names =  self.class.columns.map { |el| el.to_s + ' = ?' }
    col_names = col_names.join(',')

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL

  end

  def save
    self.update if !self.id.nil?
    self.insert if self.id.nil?
  end
end
