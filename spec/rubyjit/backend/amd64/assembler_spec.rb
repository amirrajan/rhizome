# Copyright (c) 2017 Chris Seaton
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubyjit'

describe RubyJIT::Backend::AMD64::Assembler do

  before :each do
    @assembler = RubyJIT::Backend::AMD64::Assembler.new
  end

  describe '#push' do

    it 'correctly assembles low registers' do
      @assembler.push RubyJIT::Backend::AMD64::RBP
      expect(@assembler.bytes).to eql [0x55]
    end

    it 'correctly assembles high registers' do
      @assembler.push RubyJIT::Backend::AMD64::R15
      expect(@assembler.bytes).to eql [0x41, 0x57]
    end

    it 'handles all registers' do
      RubyJIT::Backend::AMD64::REGISTERS.each do |r|
        @assembler.push r
      end
    end

  end

  describe '#pop' do

    it 'correctly assembles low registers' do
      @assembler.pop RubyJIT::Backend::AMD64::RBP
      expect(@assembler.bytes).to eql [0x5d]
    end

    it 'correctly assembles high registers' do
      @assembler.pop RubyJIT::Backend::AMD64::R15
      expect(@assembler.bytes).to eql [0x41, 0x5f]
    end

    it 'handles all registers' do
      RubyJIT::Backend::AMD64::REGISTERS.each do |r|
        @assembler.pop r
      end
    end

  end

  describe '#mov' do

    it 'correctly assembles register to register' do
      @assembler.mov RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP
      expect(@assembler.bytes).to eql [0x48, 0x89, 0xe5]
    end

    it 'correctly assembles address to register' do
      @assembler.mov RubyJIT::Backend::AMD64::RSP + 10, RubyJIT::Backend::AMD64::RBP
      expect(@assembler.bytes).to eql [0x48, 0x8b, 0x6c, 0x0a]
    end

    it 'correctly assembles register to address' do
      @assembler.mov RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP + 10
      expect(@assembler.bytes).to eql [0x48, 0x89, 0x65, 0x0a]
    end

    it 'correctly assembles small value to register' do
      @assembler.mov RubyJIT::Backend::AMD64::Value.new(14), RubyJIT::Backend::AMD64::RAX
      expect(@assembler.bytes).to eql [0xb8, 0x0e, 0x00, 0x00, 0x00]
    end

    it 'correctly assembles big value to register' do
      @assembler.mov RubyJIT::Backend::AMD64::Value.new(0x1234567812345678), RubyJIT::Backend::AMD64::RAX
      expect(@assembler.bytes).to eql [0x48, 0xb8, 0x78, 0x56, 0x34, 0x12, 0x78, 0x56, 0x34, 0x12]
    end

    it 'correctly assembles negative offsets' do
      @assembler.mov RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP - 10
      expect(@assembler.bytes).to eql [0x48, 0x89, 0x65, 0xf6]
    end

    it 'handles all low registers' do
      RubyJIT::Backend::AMD64::LOW_REGISTERS.each do |r1|
        RubyJIT::Backend::AMD64::LOW_REGISTERS.each do |r2|
          @assembler.mov r1, r2
        end
      end
    end

  end

  describe '#add' do

    it 'correctly assembles' do
      @assembler.add RubyJIT::Backend::AMD64::RSP, RubyJIT::Backend::AMD64::RBP
      expect(@assembler.bytes).to eql [0x48, 0x01, 0xe5]
    end

    it 'handles all low registers' do
      RubyJIT::Backend::AMD64::LOW_REGISTERS.each do |r1|
        RubyJIT::Backend::AMD64::LOW_REGISTERS.each do |r2|
          @assembler.add r1, r2
        end
      end
    end

  end

  describe '#shr' do

    it 'correctly assembles' do
      @assembler.shr RubyJIT::Backend::AMD64::RCX, RubyJIT::Backend::AMD64::RAX
      expect(@assembler.bytes).to eql [0x48, 0xd3, 0xe8]
    end

    it 'handles all low registers' do
      RubyJIT::Backend::AMD64::LOW_REGISTERS.each do |r|
        @assembler.shr RubyJIT::Backend::AMD64::RCX, r
      end
    end

  end

  describe '#shl' do

    it 'correctly assembles' do
      @assembler.shl RubyJIT::Backend::AMD64::RCX, RubyJIT::Backend::AMD64::RAX
      expect(@assembler.bytes).to eql [0x48, 0xd3, 0xe0]
    end

    it 'handles all low registers' do
      RubyJIT::Backend::AMD64::LOW_REGISTERS.each do |r|
        @assembler.shl RubyJIT::Backend::AMD64::RCX, r
      end
    end

  end

  describe '#jmp' do

    it 'correctly assembles a backward jump' do
      head = @assembler.label
      @assembler.jmp head
      expect(@assembler.bytes).to eql [0xe9, 0xfb, 0xff, 0xff, 0xff]
    end

    it 'correctly assembles a backward jump over another instruction' do
      head = @assembler.label
      @assembler.nop
      @assembler.jmp head
      expect(@assembler.bytes).to eql [0x90, 0xe9, 0xfa, 0xff, 0xff, 0xff]
    end

    it 'correctly assembles a forward jump' do
      head = @assembler.jmp
      @assembler.label head
      expect(@assembler.bytes).to eql [0xe9, 0x00, 0x00, 0x00, 0x00]
    end

    it 'correctly assembles a forward jump over another instruction' do
      head = @assembler.jmp
      @assembler.nop
      @assembler.label head
      expect(@assembler.bytes).to eql [0xe9, 0x01, 0x00, 0x00, 0x00, 0x90]
    end

  end

  describe '#je' do

    it 'correctly assembles a backward jump' do
      head = @assembler.label
      @assembler.je head
      expect(@assembler.bytes).to eql [0x0f, 0x84, 0xfa, 0xff, 0xff, 0xff]
    end

  end

  describe '#jne' do

    it 'correctly assembles a backward jump' do
      head = @assembler.label
      @assembler.jne head
      expect(@assembler.bytes).to eql [0x0f, 0x85, 0xfa, 0xff, 0xff, 0xff]
    end

  end

  describe '#ret' do

    it 'correctly assembles' do
      @assembler.ret
      expect(@assembler.bytes).to eql [0xc3]
    end

  end

  describe '#nop' do

    it 'correctly assembles' do
      @assembler.nop
      expect(@assembler.bytes).to eql [0x90]
    end

  end

end
