# Copyright (c) 2016-2017 Chris Seaton
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

module RubyJIT
  module Fixtures

    def self.add(a, b)
      a + b
    end

    def self.fib(n)
      if n < 2
        n
      else
        fib(n - 1) + fib(n - 2)
      end
    end

    ADD_BYTECODE_MRI = <<END
local table (size: 2, argc: 2 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 2] a<Arg>     [ 1] b<Arg>     
0000 trace            8                                               (  27)
0002 trace            1                                               (  28)
0004 getlocal_OP__WC__0 4
0006 getlocal_OP__WC__0 3
0008 opt_plus         <callinfo!mid:+, argc:1, ARGS_SIMPLE>, <callcache>
0011 trace            16                                              (  29)
0013 leave                                                            (  28)
END

    FIB_BYTECODE_MRI = <<END
local table (size: 1, argc: 1 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 1] n<Arg>     
0000 trace            8                                               (  31)
0002 trace            1                                               (  32)
0004 getlocal_OP__WC__0 3
0006 putobject        2
0008 opt_lt           <callinfo!mid:<, argc:1, ARGS_SIMPLE>, <callcache>
0011 branchunless     19
0013 trace            1                                               (  33)
0015 getlocal_OP__WC__0 3
0017 jump             45                                              (  32)
0019 trace            1                                               (  35)
0021 putself          
0022 getlocal_OP__WC__0 3
0024 putobject_OP_INT2FIX_O_1_C_ 
0025 opt_minus        <callinfo!mid:-, argc:1, ARGS_SIMPLE>, <callcache>
0028 opt_send_without_block <callinfo!mid:fib, argc:1, FCALL|ARGS_SIMPLE>, <callcache>
0031 putself          
0032 getlocal_OP__WC__0 3
0034 putobject        2
0036 opt_minus        <callinfo!mid:-, argc:1, ARGS_SIMPLE>, <callcache>
0039 opt_send_without_block <callinfo!mid:fib, argc:1, FCALL|ARGS_SIMPLE>, <callcache>
0042 opt_plus         <callinfo!mid:+, argc:1, ARGS_SIMPLE>, <callcache>
0045 trace            16                                              (  37)
0047 leave                                                            (  35)
END

    ADD_BYTECODE_RBX = <<END
[2, 0, 2, [:a, :b]]
0000:  push_local                 0    # a
0002:  push_local                 1    # b
0004:  send_stack                 :+, 1
0007:  ret
END

    FIB_BYTECODE_RBX = <<END
[1, 0, 1, [:n]]
0000:  push_local                 0    # n
0002:  push_int                   2
0004:  send_stack                 :<, 1
0007:  goto_if_false              0013:
0009:  push_local                 0    # n
0011:  goto                       0040:
0013:  push_self
0014:  push_local                 0    # n
0016:  push_int                   1
0018:  send_stack                 :-, 1
0021:  allow_private
0022:  send_stack                 :fib, 1
0025:  push_self
0026:  push_local                 0    # n
0028:  push_int                   2
0030:  send_stack                 :-, 1
0033:  allow_private
0034:  send_stack                 :fib, 1
0037:  send_stack                 :+, 1
0040:  ret
END

    ADD_BYTECODE_JRUBY = <<END
[DEAD]%self = recv_self()
%v_0 = load_implicit_closure()
%current_scope = copy(scope<0>)
%current_module = copy(module<0>)
check_arity(;req: 2, opt: 0, *r: false, kw: false)
a(0:0) = recv_pre_reqd_arg()
b(0:1) = recv_pre_reqd_arg()
line_num(;n: 27)
%v_3 = call_1o(a(0:0), b(0:1) ;n:+, t:NO, cl:false)
return(%v_3)
END

    FIB_BYTECODE_JRUBY = <<END
[DEAD]%self = recv_self()
%v_0 = load_implicit_closure()
%current_scope = copy(scope<0>)
%current_module = copy(module<0>)
check_arity(;req: 1, opt: 0, *r: false, kw: false)
n(0:0) = recv_pre_reqd_arg()
line_num(;n: 31)
%v_3 = call_1f(n(0:0), Fixnum:2 ;n:<, t:NO, cl:false)
b_false(LBL_0:13, %v_3)
line_num(;n: 32)
%v_4 = copy(n(0:0))
jump(LBL_1:21)
label(LBL_0:13)
line_num(;n: 34)
%v_5 = call_1f(n(0:0), Fixnum:1 ;n:-, t:NO, cl:false)
%v_6 = call_1o(%self, %v_5 ;n:fib, t:FU, cl:false)
%v_8 = call_1f(n(0:0), Fixnum:2 ;n:-, t:NO, cl:false)
%v_9 = call_1o(%self, %v_8 ;n:fib, t:FU, cl:false)
%v_7 = call_1o(%v_6, %v_9 ;n:+, t:NO, cl:false)
%v_4 = copy(%v_7)
label(LBL_1:21)
return(%v_4)
END

    ADD_BYTECODE_RUBYJIT = [
        [:arg,      0       ],
        [:store,    :a      ],
        [:arg,      1       ],
        [:store,    :b      ],
        [:trace,    27      ],
        [:trace,    28      ],
        [:load,     :a      ],
        [:load,     :b      ],
        [:send,     :+,   1 ],
        [:trace,    29      ],
        [:return            ]
    ]

    FIB_BYTECODE_RUBYJIT = [
        [:arg,      0       ],
        [:store,    :n      ],
        [:trace,    31      ],
        [:trace,    32      ],
        [:load,     :n      ],
        [:push,     2       ],
        [:send,     :<,   1 ],
        [:not               ],
        [:branch  , 12      ],
        [:trace,    33      ],
        [:load,     :n      ],
        [:jump,     24      ],
        [:trace,    35      ],
        [:self              ],
        [:load,     :n      ],
        [:push,     1       ],
        [:send,     :-,   1 ],
        [:send,     :fib, 1 ],
        [:self              ],
        [:load,     :n      ],
        [:push,     2       ],
        [:send,     :-,   1 ],
        [:send,     :fib, 1 ],
        [:send,     :+,   1 ],
        [:trace,    37      ],
        [:return            ]
    ]

    def self.mask_traces(insns)
      insns = insns.reject { |i| i.first == :trace }

      insns.map do |insn|
        if [:jump, :branch].include?(insn.first)
          insn = insn.dup
          insn[1] = 0
        end
        insn
      end
    end

    ADD_BYTECODE_RUBYJIT_FROM_JRUBY = [
        [:arg,      0       ],
        [:store,    :a      ],
        [:arg,      1       ],
        [:store,    :b      ],
        [:trace,    27      ],
        [:load,     :a      ],
        [:load,     :b      ],
        [:send,     :+,   1 ],
        [:store,    :v_3    ],
        [:load,     :v_3    ],
        [:return            ]
    ]

    FIB_BYTECODE_RUBYJIT_FROM_JRUBY = [
        [:arg,      0       ],
        [:store,    :n      ],
        [:trace,    31      ],
        [:load,     :n      ],
        [:push,     2       ],
        [:send,     :<,   1 ],
        [:store,    :v_3    ],
        [:load,     :v_3    ],
        [:not               ],
        [:branch,   14      ],
        [:trace,    32      ],
        [:load,     :n      ],
        [:store,    :v_4    ],
        [:jump,     37      ],
        [:trace,    34      ],
        [:load,     :n      ],
        [:push,     1       ],
        [:send,     :-,   1 ],
        [:store,    :v_5    ],
        [:self              ],
        [:load,     :v_5    ],
        [:send,     :fib, 1 ],
        [:store,    :v_6    ],
        [:load,     :n      ],
        [:push,     2       ],
        [:send,     :-,   1 ],
        [:store,    :v_8    ],
        [:self              ],
        [:load,     :v_8    ],
        [:send,     :fib, 1 ],
        [:store,    :v_9    ],
        [:load,     :v_6    ],
        [:load,     :v_9    ],
        [:send,     :+,   1 ],
        [:store,    :v_7    ],
        [:load,     :v_7    ],
        [:store,    :v_4    ],
        [:load,     :v_4    ],
        [:return            ]
    ]

  end
end
