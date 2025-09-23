--[[This file is part of Plume

Plume🪶 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License.

Plume🪶 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Plume🪶.
If not, see <https://www.gnu.org/licenses/>.
]]

return function (plume)
    local function buildGrammar()
        local lpeg = require "lpeg"

        local S, R, P, V, Cp = lpeg.S, lpeg.R, lpeg.P, lpeg.V, lpeg.Cp

        local function C(name, pattern)
            return Cp() * lpeg.C(pattern) * Cp() / function(bpos, content, epos)
                return {
                    name = name,
                    bpos = bpos,
                    epos  = epos-1,
                    content = content
                }
            end
        end

        local function Cc(name, pattern)
            return Cp() * lpeg.Cc(pattern) * Cp() / function(bpos, content, epos)
                return {
                    name = name,
                    bpos = bpos,
                    epos  = epos-1,
                    content = content
                }
            end
        end

        local function NOT(pattern)
            return (P(1) - pattern)
        end

        local function E(errorHandler, pattern)
        	pattern = pattern or NOT(S"\n")^0
            return Cp() * lpeg.C(pattern) * Cp() / function(bpos, content, epos)
                return {
                    name = name,
                    bpos = bpos,
                    epos  = epos-1,
                    content = content,
                    error = errorHandler
                }
            end
        end

        local function Ct(name, pattern)
            return Cp() * lpeg.Ct(pattern) * Cp() / function(bpos, children, epos)
                return {
                	name=name, 
                	bpos=bpos,
                	epos=epos-1,
                	children=children
                }
            end
        end

        ------------
        -- common --
        ------------
        local s  = S" \t"^1
        local os = S" \t"^0
        local lt = (os * S";\n")^1 * os -- linestart
        local num = C("NUMBER", (R"09"^1 * P"." * R"09"^1) + R"09"^1)
        -- strict identifier
        local idns = C("IDENTIFIER", (R"az"+R"AZ"+P"_") * (R"az"+R"AZ"+P"_"+R"09")^0)
        local idn = C("TRUE", P"true")
        		  + C("FALSE", P"false")
        		  + C("EMPTY", P"empty")
        		  + idns
        local escaped = P"\\s" * Cc("TEXT", " ")
                      + P"\\t" * Cc("TEXT", "\t")
                      + P"\\n" * Cc("TEXT", "\n")
                      + P"\\"*C("TEXT", P(1))

        ----------
        -- eval --
        ----------
        local function fold_bin(t)
        	if #t == 1 then return t[1] end
            local ast = t[1]
            for i = 2, #t, 2 do
                local operator = t[i]
                local right = t[i+1]
                ast = {
                	name = operator.name,
                	bpos = ast.bpos,
                	epos = right.epos,
                	children = {
                		ast, 
                		right
                	}
                }
            end
            
            return ast
        end

        local function fold_un(t)
        	if #t == 1 then return t[1] end
            local ast = t[#t]
            for i = #t - 1, 1, -1 do
                local operator = t[i]
                ast = {
                	name = operator.name,
                	bpos = operator.bpos,
                	epos = ast.epos,
                	children = {
                		ast
                	}
                }
            end
            
            return ast
        end

        local quoteText = C("TEXT", NOT(S'"\\')^1)
        local quoteEscape = P"\\"*C("ESCAPED", P(1))
        local quote = P'"' * Ct("QUOTE", (quoteEscape + quoteText)^0) * P'"'

        local opplist = {
            {{"OR",  "or"}},
            {{"AND", "and"}},
            {{"NOT", "not"}, unary=true},
            {{"EQ", "=="}, {"NEQ", "!="}, {"LTE", "<="}, {"GTE", ">="}, {"LT", "<"}, {"GT", ">"}},
            {{"NEG", "-"}, unary=true},
            {{"ADD", "+"}, {"SUB", "-"}},
            {{"MUL", "*"}, {"DIV", "/"}, {"MOD", "%"}},
            {{"POW", "^"}},
        }

        local function genALU()
            local rules = {"_layer1"}

            for deep, opps in ipairs(opplist) do
                local rule
                for i, opp in ipairs(opps) do
                    local name, pattern, unary = opp[1], opp[2], opp[3]
                    local opprule = C(name, P(pattern))
                    if i==1 then
                        rule = opprule
                    else
                        rule = rule + opprule
                    end
                end
                local current = "_layer" .. deep
                local next    = "_layer" .. (deep+1)
                if opps.unary then
                    rules[current] =  lpeg.Ct((rule * os)^0 * V(next)) / fold_un
                else
                    rules[current] = lpeg.Ct(V(next) * (os * rule * os * V(next))^0) / fold_bin
                end
            end


            -- Eval & index
            local posarg  = Ct("LIST_ITEM", V"_layer1")
            local optnarg = Ct("HASH_ITEM", idn*os*P":"*os*Ct("BODY", V"_layer1"^-1))
            local arg = optnarg + posarg
            local arglist = Ct("CALL", P"(" * arg^-1 * (os * P"," * os * arg)^0 * P")")
            local index = Ct("INDEX", P"[" * V"_layer1" * P"]")
        	local directindex = Ct("DIRECT_INDEX", P"." * idn)

            local evalOpperator = arglist + index + directindex
        	local access = Ct("EVAL", idn * evalOpperator^1)
        	---

            local terminal = num + access + idn + quote
            rules["_layer" .. (#opplist+1)] = os * (terminal + P"(" * V("_layer1") * P")") * os

            return rules
        end

        local expr = Ct("EXPR", genALU())
        local evalBase = Ct("EVAL", (P"(" * expr * P")" + idn) * V"evalOpperator"^0)
        local eval = P"$" * evalBase
        local index = Ct("INDEX", P"[" * expr * P"]")
        local directindex = Ct("DIRECT_INDEX", P"." * idn)

        --------------
        -- commands --
        --------------
        -- common
        local iterator  = s * (P"in") * s * Ct("ITERATOR", expr)
                        + E(plume.error.missingIteratorError)
        
        local condition = s * Ct("CONDITION", expr) + E(plume.error.missingConditionError)
        local body      = Ct("BODY", V"statement"^0)
        local _end      = lt * P"end" + E(plume.error.missingEndError)

        -- if/elseif/else
        local _else   = Ct("ELSE", lt*P"else" * body)
        local _elseif = Ct("ELSEIF", lt*P"elseif" * condition * body)
        local _if     = Ct("IF", P"if" * condition * body * _elseif^0 * _else^-1 * _end)

        -- loops
        local forInd = idn + E(plume.error.missingLoopIndentifierError)
        local _while = Ct("WHILE", P"while" * condition * body * _end)
        local _for   = Ct("FOR", P"for" * s * forInd * iterator * body * _end)

        -- macro & calls
        local function sugarFlagParam(p)
        	return p / function(capture)
        		capture.name = "PARAM"
        		table.insert(capture.children, {
        			name="BODY",
        			bpos=capture.bpos,
        			epos=capture.epos,
        			children={{
            			name="EVAL",
            			bpos=capture.bpos,
            			epos=capture.epos,
            			children={{
            				name = "FALSE",
            				bpos=capture.bpos,
            				epos=capture.epos,
        				}}
        			}},
        		})
        		return capture
        	end
        end
        local function sugarFlagCall(p)
        	return p / function(capture)
        		capture.name = "HASH_ITEM"
        		table.insert(capture.children, {
        			name="BODY",
        			bpos=capture.bpos,
        			epos=capture.epos,
        			children={{
            			name="EVAL",
            			bpos=capture.bpos,
            			epos=capture.epos,
            			children={{
            				name = "TRUE",
            				bpos=capture.bpos,
            				epos=capture.epos,
        				}}
        			}},
        		})
        		return capture
        	end
        end

        local param      = Ct("PARAM",
                			      idn * os * P":" * os * Ct("BODY", V"textic"^-1)
                    			+ idn
                    			+ Ct("VARIADIC", P"..." * idn)
                    		) + sugarFlagParam(Ct("FLAG", "?"*idn))
                    		
        local paramlist  = Ct("PARAMLIST", P"(" * param^-1 * (os * P"," * os * param)^0 * P")")
        local paramlistM = paramlist + E(plume.error.missingParamListError)
        local macro      = Ct("MACRO", P"macro" * (s * idn)^-1 * os * paramlistM * body * _end)

        local arg       = Ct("HASH_ITEM", idn * os * P":" * os * Ct("BODY", V"textic"^-1))	
        				+ sugarFlagCall(Ct("FLAG", "?"*idn))
                        + Ct("EXPAND", P"..."*evalBase)
                        + Ct("LIST_ITEM", V"textic")

        local call      = Ct("CALL", P"(" * arg^-1 * (os * P"," * os * arg)^0 * P")")
        -- local block     = Ct("BLOCK", P"@" * idn * os * call^-1 * body * _end)
        local block = Ct("EVAL", P"@" * idn * (index + directindex)^0 * os
        					* Ct("BLOCK_CALL", call^-1 * body)
        				* _end)

        -- affectations
        local lbody    = Ct("BODY", V"firstStatement")
        local statconst = (s * C("STATIC", P"static"))^-1 * (s * C("CONST", P"const"))^-1
        local idnList = idn * (os * P"," * os * idn)^0
        local let = Ct("LET", P"let" * statconst *  (
        						  s * idn * os * C("EQ", P"=")   * lbody
        						+ s * idnList * s  * C("FROM", P"from") * s * Ct("EVAL", expr)
                                + s * idn
        					)^-1)
        local compound = Ct("COMPOUND", C("ADD", P"+") + C("SUB", P"-")
                       + C("MUL", P"*") + C("DIV", P"/"))

        local setvar = Ct("EVAL", (idn * V"evalOpperator"^1)) + idn
        local set = Ct("SET", P"set" * s * setvar * (os * compound^-1 * P"=" * lbody))

        -- table
        local listitem = Ct("LIST_ITEM", P"- " * os * V"firstStatement") 
        local hashitem = Ct("HASH_ITEM", Ct("META", P"meta"*s)^-1 * idn * P":" *  os *lbody)
        local expand   = Ct("EXPAND", P"..." * evalBase) 

        ----------
        -- main --
        ----------
        local rules = {
            "program",
            program = V"firstStatement"^-1 * V"statement"^0,

            statementTerminator = P"elseif" + P"else" + P"end",
            firstStatement = os * (-V"statementTerminator")
                                * (V"command" +  V"invalid"^-1 * V"text"),
            statement    = lt * (Ct("DO", P"do" * s * V"firstStatement") + V"firstStatement"),

            command =  _if + _while + _for + macro + block + let + set + listitem + hashitem + expand,

            text =   (escaped + eval + V"comment" + V"rawtext")^1,
            textic = (escaped + eval + V"comment" + V"rawtextic")^1,

            comment   = P"//" * C("COMMENT", NOT(S"\n")^0),
            rawtext   = C("TEXT", NOT(S"$\n\\" + P"//")^1),
            rawtextic = C("TEXT", NOT(S"$\n,)\\"+ P"//")^1),

            invalid = E(plume.error.emptySetError, P"set"),
            evalOpperator = call + index + directindex
        }

        return lpeg.Ct(rules)
    end

    local grammar = buildGrammar()

    function plume.parse(code, filename)
        -- parse will fail if empty line at programm end.
        -- dirty quick fix
        code = code:gsub('%s*$', '')

        local ast = {
            name="FILE",
            children=lpeg.match(grammar, code),
            bpos=1,
            epos=1
        }
        
        plume.ast.set(ast, "filename", filename)
        plume.ast.set(ast, "code", code)

        -- Retrieve error if captured, else
        -- check if all the file has been parsed
        local pos = 0
        plume.ast.browse(ast, function (node)
            if node.error then
                node.error(node)
            end

            if node.epos and node.epos > pos then
                pos = node.epos
            end
        end)

        if pos < #code then
            plume.error.malformedCodeError({
                filename = filename,
                code = code,
                bpos = pos,
                epos = #code
            })
        end
        
        plume.ast.markType(ast)
        ast.pos = pos
        return ast
    end

end