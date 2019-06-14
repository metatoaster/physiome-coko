start = content:topLevel { return content; }

// ----- Base Types -----

begin_array     = ws "[" ws
begin_object    = ws "{" ws
end_array       = ws "]" ws
end_object      = ws "}" ws
name_separator  = ws ":" ws
value_separator = ws "," ws

ws "whitespace" = [ \t\n\r]*

value
  = false
  / null
  / true
  / number
  / string

false = "false" { return false; }
null  = "null"  { return null;  }
true  = "true"  { return true;  }

valueArray "value array"
	= begin_array head:value? ws tail:(value_separator v:value { return v; })* end_array
    {
    	if(!head) {
        	return [];
        }
    	const r = [head];
        if(tail && tail.length) {
        	r.push.apply(r, tail);
        }
        return r;
    }

valueOrValueArray =  valueArray / value

mappingReference "mapping reference"
	= ws "mapping(" ws mappingName:string ws ")" ws
    { return {type: "mapping", mapping:mappingName}; }


// ----- Numbers -----

number "number"
  = minus? int frac? exp? { return parseFloat(text()); }

decimal_point
  = "."

digit1_9
  = [1-9]

e
  = [eE]

exp
  = e (minus / plus)? DIGIT+

frac
  = decimal_point DIGIT+

int
  = zero / (digit1_9 DIGIT*)

minus
  = "-"

plus
  = "+"

zero
  = "0"

// ----- Strings -----

string "string"
  = quotation_mark chars:char* quotation_mark { return chars.join(""); }

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape
  = "\\"

quotation_mark
  = '"'

unescaped
  = [^\0-\x1F\x22\x5C]

DIGIT  = [0-9]
HEXDIG = [0-9a-f]i


// ----- Property Object -----

properyObject = begin_object
					first:(name:propName name_separator value:value { return {n:name, v:value}; })
                    rest:(v:(name:propName name_separator value:value) { return {n:name, v:value}; } )*
				end_object
                {
                	var r = {};
                    if(first) {
                    	r[first.n] = first.v;
                    }
                    if(rest) {
                    	rest.forEach(function(a) {
                            r[a.n] = a.v;
                        });
                    }
                	return r;
                }

propertyList = values:(
		value_separator name:propName name_separator value:value
    	{return {n:name, v:value};}
    )*
	{
    	if(!values || !values.length) {
        	return null;
        }
    	const prop = {};
        values.forEach(f => {
        	prop[f.n] = f.v;
        });
        return prop;
    }



// ----- Special Types -----

propName "prop name"
  = first:[a-z_$]i rest:[a-z0–9_$]i* { return first + rest.join("") }

typeName "type name"
  = first:[a-z_$]i rest:[a-z0–9_$]i* { return first + rest.join("") }

targetModelName "target model property name"
  = first:[a-z_$]i rest:[a-z0–9_$.]i* { return first + rest.join("") }


// ----- Top Level -----
topLevel = ws content:(task / model / enum / mapping)* ws
  {
  	    const m = {};

  		const tasks = content.filter(c => c.type === "task");
        if(tasks.length) {
        	const taskMap = {};

            tasks.forEach(task => {
            	delete task.type;
                if(task.name) {
                    taskMap[task.name] = task;
                }
            });

        	m.tasks = taskMap;
        }

  	    const models = content.filter(c => c.type === "model");
        if(models.length) {
        	const modelMap = {};

            models.forEach(model => {
            	delete model.type;
            	if(model.default) {
                	modelMap.default = model;
                } else if(model.name) {
                    modelMap[model.name] = model;
                }
            });

        	m.models = modelMap;
        }

        const enums = content.filter(c => c.type === "enum");
        if(enums.length) {
        	const enumMap = {};

            enums.forEach(e => {
            	delete e.type;
            	if(e.name) {
                    enumMap[e.name] = e;
                }
            });

        	m.enums = enumMap;
        }

        const mappings = content.filter(c => c.type === "mapping");
        if(mappings.length) {
        	const mappingMap = {};

            mappings.forEach(e => {
            	delete e.type;
            	if(e.name) {
                    mappingMap[e.name] = e;
                }
            });

        	m.mappings = mappingMap;
        }

		return m;
  }


// ----- Task -----

task
	= "instance" ws taskName:propName ws? begin_object ws? content:taskContent ws? end_object
	{
      var m = {type:"task", name:taskName};

      if(content && content.length) {
        const options = content.filter(c => c.type === "options");
        if(options.length) {
			const opts = {};
            options.forEach(op => {
            	Object.assign(opts, op);
            });
            delete opts.type;
            m.options = opts;
		}


        const models = content.filter(c => c.type === "model");
        if(models.length) {
        	m.model = models[0];
        }

        const enums = content.filter(c => c.type === "enum");
        if(enums.length) {
        	const enumMap = {};

            enums.forEach(e => {
            	delete e.type;
            	if(e.name) {
                    enumMap[e.name] = e;
                }
            });

        	m.enums = enumMap;
        }

        const forms = content.filter(c => c.type === "form");
        if(forms.length) {
        	m.forms = forms.map(form => {
            	delete form.type;
            	return form;
            });
        }

        const views = content.filter(c => c.type === "view");
        if(views.length) {
        	m.views = views.map(form => {
            	delete form.type;
            	return form;
            });
        }

        const acls = content.filter(c => c.type === "acl");
        if(acls.length) {

        	m.acl = {};
            m.acl.fields = {};
            m.acl.tasks = {};
            m.acl.rules = [];

        	acls.forEach(acl => {
            	if(acl.fields) {
                	Object.assign(m.acl.fields, acl.fields);
                }
                if(acl.tasks) {
                	Object.assign(m.acl.tasks, acl.tasks);
                }
                if(acl.rules) {
                	m.acl.rules.push.apply(m.acl.rules, acl.rules);
                }
            	return acl;
            });
        }
      }
      return m;
    }

taskContent = (taskSpecificModel / enum / form / view / taskOptions / taskListingAccessor / acl)*

// Task options
taskOptions = ws "processKey" name_separator processKey:string? {return {type:"options", processKey}}

taskListingAccessor = ws "listingAccessor" name_separator listingAccessor:string {return {type:"options", listingAccessor}}

// ---- Enum ------
enum
	= ws "enum" ws enumName:propName
    begin_object
    first:enumValue?
    rest:("," ws v:enumValue {return v;})*
    end_object
    {
    	if(!first) {
            return {type:"enum", name:enumName};
        }
        const r = [first];
        if(rest && rest.length) {
        	r.push.apply(r, rest);
        }
        const values = {};
        r.forEach(v => {
        values[v.name] = v.value;
        });
    	return {type:"enum", name:enumName, values:values};
    }

enumValue
	= ws value:propName mapping:(ws "=>" ws v:value {return v;})? ws
	{
    	const r = {name:value, value:value};
        if(mapping) {
        	r.value = mapping;
            r.mapped = true;
        }
    	return r;
    }

// ----- Model -----

model
	= ws "model" ws isInput:("+" ws "input")? ws modelName:string? def:modelDefault? ws options:modelOptions? ws
    begin_object
    first:modelElement?
    rest:(ws "," ws e:modelElement {return e;})*
    end_object
    {
    	var m = {type:"model", };
        if(modelName) {
        	m.name = modelName;
        }
        if(isInput) {
        	m.input = true;
        }
        if(options) {
        	Object.assign(m, options);
        }
        if(first) {
        	m.elements = [first];
            if(rest) {
                m.elements.push.apply(m.elements, rest);
            }
        }
        if(def === true) {
        	m.default = true;
        }
        return m;
    }

taskSpecificModel
	= ws "model" ws isInput:("+" ws "input")? ws options:modelOptions? ws modelName:string?
    begin_object
    first:modelElement?
    rest:(ws "," ws e:modelElement {return e;})*
    end_object
    {
    	var m = {type:"model"};
        if(modelName) {
        	m.name = modelName;
        }
        if(isInput) {
        	m.input = true;
        }
        if(options) {
        	Object.assign(m, options);
        }
        if(first) {
        	m.elements = [first];
            if(rest) {
                m.elements.push.apply(m.elements, rest);
            }
        }
        return m;
    }

modelOptions
    = "<" ws first:modelAllOptions? rest:("," ws opt:modelAllOptions {return opt;})? ">"
    {
    	if(!first) {
        	return null;
        }
        const opts = {};
        Object.assign(opts, first);
        if(rest && rest.length) {
        	rest.forEach(r => {
                Object.assign(opts, r);
            });
        }
    	return opts;
    }

modelAllOptions = modelOptionNoCreate

modelOptionNoCreate
	= "no-create"
    {
    	return {noCreate:true};
    }

modelDefault
    = ws "default" ws
    {
    	return true;
    }

modelElement
	= fieldName:propName ws ":" ws type:modelTypeName ws details:modelElementDetails?
    {
    	var m = {field:fieldName, type:type.type};
        if(type.array) {
        	m.array = true;
        }

        if(details) {

          if(details.access && details.access.length) {
              m.access = details.access;
          }

          if(details.options) {
          	Object.assign(m, details.options);
          }
        }

        return m;
    }

modelTypeName = (modelArrayTypeName / modelBasicTypeName)

modelBasicTypeName
	= type:typeName { return {type:type}; }

modelArrayTypeName
	= "[" type:typeName "]"
    {
    	return {array:true, type:type};
    }

modelElementDetails
    = "<" first:modelElementDetailsType ws other:("," ws element:modelElementDetailsType {return element;})* ws ">" ws
    {
    	const parts = (other && other.length) ? [first, ...other] : [first];
        const access = parts.filter(t => t.type === "access");
        const options = parts.filter(t => t.type === "options");
    	const r = {};

        if(access) {
        	r.access = access.map(a => {
            	delete a.type;
            	return a;
            });
        }

        if(options) {
        	const o = {};
            const accessors = [];

            options.forEach(a => {
            	if(a.accessors) {
                	a.accessors.forEach(v => {
                    	if(accessors.indexOf(v) === -1) {
                        	accessors.push(v);
                        }
                    })
                }
            	Object.assign(o, a)
            });
            delete o.type;

            if(accessors.length) {
            	o.accessors = accessors;
            }

            r.options = o;
        }

        return r;
    }

modelElementDetailsType = (modelElementAccessDescription / modelElementOptions)

modelElementAccessDescription
	= ws role:propName ws ":" ws? access:modelElementAccessType ws
    {
    	return {type:"access", role:role, access:access};
    }

modelElementAccessType
	= type:("read-write" / "read" / "rw" / "r")
    {
    	return (type === "rw" || type === "read-write") ? "read-write" : "read";
    }

modelElementOptions = (modelElementExclusions / modelElementJoinToDetails /
						modelElementDefaultStringValue / modelElementDefaultEnumValue /
                        modelElementJoinDetails / modelElementState / modelElementAccessors /
                        modelElementInitialOwner / modelElementListingFilterMultiple /
                        modelElementListingFilter / modelElementListingSortable /
                        modelElementFileLabel / modelElementFileType)

modelElementExclusions
	= "input:" inputExclusion:("exclude" / "include")
    {
    	// Is this model entity excluded from the "Input" type that
        // is auto generated. By default all items are included in the input
        // unless they are an array and then they needed to included via
        // input.

    	return {type:"options", input:(inputExclusion === "include")};
    }

modelElementInitialOwner
	= "owner-id"
    {
    	return {type:"options", holdsOwnerId:true};
    }

modelElementAccessors
	= accessors:("add" / "remove" / "set")
    {
    	const r = {type:"options"};
    	if(accessors === "add") {
        	r.accessors = ["add"];
        } else if(accessors === "remove") {
        	r.accessors = ["remove"];
        } else if(accessors === "set") {
        	r.accessors = ["set"];
        }

    	return r;
    }

modelElementJoinDetails
	= "join-field:" field:string
    {
    	return {type:"options", joinField:field};
    }

modelElementJoinToDetails
	= "join-to-field:" field:string
    {
    	return {type:"options", joinToField:field};
    }

modelElementState
	= "state"
    {
    	return {type:"options", state:true};
    }

modelElementListingFilter
	= "listing-filter"
    {
    	return {type:"options", listingFilter:true};
    }

modelElementListingFilterMultiple
	= "listing-filter-multiple"
    {
    	return {type:"options", listingFilter:true, listingFilterMultiple:true};
    }

modelElementListingSortable
	= "listing-sortable"
    {
    	return {type:"options", listingSorting:true};
    }

modelElementFileLabel
	= "file-labels"
    {
    	return {type:"options", fileLabels:true};
    }

modelElementFileType
	= "file-types"
    {
    	return {type:"options", fileTypes:true};
    }

modelElementDefaultStringValue
	= "default:" defaultValue:value
    {
    	return {type:"options", defaultValue:defaultValue};
    }

enumRef "enum ref"
  = first:[a-z_$]i rest:[a-z0–9_.$]i* { return first + rest.join("") }


modelElementDefaultEnumValue
	= "default:" defaultValue:enumRef
    {
    	const parts = defaultValue.split(".");
    	return {type:"options", defaultEnum:parts[0], defaultEnumKey:parts[1]};
    }


// ----- View ------

view
	= ws? "view" ws viewName:string extend:formExtends? ws
    	begin_object content:viewContent end_object ws?
    {
    	var m = {type:"view", view:viewName};
        if(extend) {
        	m.extend = extend;
        }
        if(content.options && Object.keys(content.options).length) {
        	m.options = content.options;
        }
        if(content.elements) {
        	m.elements = content.elements;
        }
        return m;
    }

viewContent
	= content:(formOptions / formElements)*
    {
    	const opts = content ? content.filter(t => t.type === "options") : null;
    	const elements = content ? content.filter(t => t.type === "elements" && t.elements.length) : null;
        const r = {};

        if(opts && opts.length) {
        	const options = {};
        	opts.forEach(opt => Object.assign(options, opt.options));
            r.options = options;
        }

        if(elements && elements.length) {
        	const consolidatedElements = [];
        	elements.forEach(e => consolidatedElements.push.apply(consolidatedElements, e.elements));
            if(consolidatedElements.length) {
            	r.elements = consolidatedElements;
            }
        }
       	return r;
    }


// ----- Form -----

form
	= ws? "form" ws formName:string extend:formExtends? ws begin_object content:formContent end_object ws?
    {
    	var m = {type:"form", form:formName};
        if(extend) {
        	m.extend = extend;
        }
        if(content.outcomes) {
        	m.outcomes = content.outcomes;
        }
        if(content.options && Object.keys(content.options).length) {
        	m.options = content.options;
        }
        if(content.elements) {
        	m.elements = content.elements;
        }
        return m;
    }

formExtends
    = ws "extend" ws ext:string
    {
    	return ext;
    }

formContent
	= content:(formOptions / formElements / formOutcomes)*
    {
    	const opts = content ? content.filter(t => t.type === "options") : null;
    	const outcomes = content ? content.filter(t => t.type === "outcomes") : null;
    	const elements = content ? content.filter(t => t.type === "elements" && t.elements.length) : null;
        const r = {};

        if(outcomes && outcomes.length) {
        	const consolidatedOutcomes = [];
        	outcomes.forEach(e => consolidatedOutcomes.push.apply(consolidatedOutcomes, e.outcomes));
            if(consolidatedOutcomes.length) {
            	r.outcomes = consolidatedOutcomes;
            }
        }

        if(opts && opts.length) {
        	const options = {};
        	opts.forEach(opt => Object.assign(options, opt.options));
            r.options = options;
        }

        if(elements && elements.length) {
        	const consolidatedElements = [];
        	elements.forEach(e => consolidatedElements.push.apply(consolidatedElements, e.elements));
            if(consolidatedElements.length) {
            	r.elements = consolidatedElements;
            }
        }
       	return r;
    }

formOptions
	= ws "options" name_separator options:properyObject
    {
    	return {type:"options", options};
    }

formOutcomes
	= ws "outcomes" name_separator
    begin_array
    first:formOutcome?
    rest:("," e:formOutcome {return e;})*
    end_array
    {
    	const r = {type:"outcomes"};
        if(first) {
        	const outcomes = [first];
            if(rest) {
            	outcomes.push.apply(outcomes, rest);
            }
            r.outcomes = outcomes;
        }
    	return r;
    }

formOutcome
	= begin_object
    type:string
    result:(ws "=>" ws result:propName {return result;})?
    state:formOutcomeStateSet?
    idAssign:formOutcomeIdentityAssignment?
    propList:propertyList?
    end_object
    {
    	const r = {type:type};
        r.result = result || "Complete";
        if(propList) {
            Object.keys(propList).forEach(k => {
          	if(propList[k]) {
            	r[k] = propList[k];
            }
          });
        }
        if(state) {
        	r.state = state;
        }
        if(idAssign) {
        	r.identityAssignment = idAssign.destination;
        }
        return r;
    }

formOutcomeStateSet
 	= ws "," ws "state" ws ":"
    begin_object
    first:formOutcomeStateKeyValuePair?
    rest:("," value:formOutcomeStateKeyValuePair {return value})*
    end_object
    {
    	if(!first) {
        	return null;
        }
        const v = [first, ...(rest || [])];
        const r = {};

        v.forEach(kp => {
        	r[kp.key] = kp;
            delete kp.key;
        });
    	return r;
    }

formOutcomeStateKeyValuePair
	= ws name:propName name_separator value:(formOutcomeStateSimpleValue / formOutcomeStateEnumValue)
    {
    	return Object.assign({key:name}, value);
    }

formOutcomeStateSimpleValue
	= value:value
    {
        return {type:"simple", value:value};
    }

formOutcomeStateEnumValue
	= value:enumRef
    {
    	return {type:"enum", value:value};
    }

formOutcomeIdentityAssignment
	= ws "identity" ws "=>" ws dest:propName
    {
    	return {type:"identity-assign", destination:dest};
    }

formElements
	= ws "elements" name_separator begin_object elements:(formElement)* end_object
    {
    	return {type:"elements", elements:elements};
    }

formElement
	= begin_object
    type:propName
    binding:formElementBinding?
    condition:(value_separator c:Condition {return c;})?
    options:formElementExtendedOptions?
    end_object
    {
    	const r = {element:type};
       	if(binding) {
        	r.binding = binding;
        }
        if(condition) {
        	r.condition = condition;
        }
        if(options) {
        	if(options.children) {
            	r.children = options.children;
                delete options.children;
            }

            if(Object.keys(options).length) {
            	r.options = options;
            }
        }
        return r;
    }

formElementBinding
	= binding:formElementSimpleBinding

formElementSimpleBinding
	= (ws "=>" ws modelTarget:targetModelName {return modelTarget;})

formElementExtendedOptions
	= extendedOptions:(formElementChildren / formElementOption)*
    {
    	const children = [];
        const r = {};

        if(extendedOptions.length) {
        	extendedOptions.forEach(opt => {
            	if(opt.children) {
                	children.push.apply(children, opt.children);
                } else {
                	Object.assign(r, opt);
                }
            });
        }

        if(children.length) {
        	r.children = children;
        }

        return Object.keys(r).length ? r : null;
    }

formElementChildren
	= value_separator "children" name_separator begin_object elements:(formElement)* end_object
    {
    	return {children: elements}
    }

formElementOption
    = value_separator key:propName name_separator value:formElementOptionValue
    {
    	const r = {};
        r[key] = value;
    	return r;
    }

formElementOptionValue
 	= mappingReference / valueArray / value



// ---- Conditions


Condition
	= ws "(" ws expression:ConditionalGroup ws ")" ws
    {
    	return {type:"condition", expression:expression};
    }

ConditionalGrouping
	= "(" ws expression:ConditionalGroup ws ")"
    {
    	return {type:"group", expression:expression};
    }

ConditionalGroup
	= expression:ConditionalExpression tail:(ConditionalContinuation)*
    {
    	const v = [expression];
        if(tail && tail.length) {
        	v.push.apply(v, tail);
        }
        return v;
    }

ConditionalContinuation
	= ws type:("&&" / "||") ws expression:(ConditionalGrouping / ConditionalExpression)
    {
    	return {op:type, expression:expression};
    }

ConditionalExpression
	= ws lhs:ConditionModelTargetValue ws operation:ConditionOperation ws rhs:ConditionValue
    {
    	return {op:operation, lhs:lhs, rhs:rhs};
    }

ConditionOperation
	= ("!=" / "==" / "in")

ConditionValue
	= (ConditionEnumSetValue / ConditionEnumValue / ConditionSimpleValue)

ConditionModelTargetValue
	= value:targetModelName
    { return {type:"model", value:value}; }

ConditionEnumSetValue
	= begin_array head:enumRef tail:(value_separator v:enumRef {return v;})* end_array
    {
    	const v = [head];
        if(tail && tail.length) {
        	v.push.apply(v, tail);
        }
    	return {type:"enum-set", value:v};
    }

ConditionSimpleValue
	= value:value
    {
        return {type:"simple", value:value};
    }

ConditionEnumValue
	= value:enumRef
    {
    	return {type:"enum", value:value};
    }




// ---- ACL

acl "acl"
	= ws "acl" begin_object content:aclContent* end_object
    {
    	const r = {type:"acl"};

        const fields = content.filter(c => c.type === "fields");
        if(fields.length) {
            r.fields = {};
            fields.forEach(f => {
                delete f.type;
            	r.fields[f.name] = f
            });
        }

        const tasks = content.filter(c => c.type === "tasks");
        if(tasks.length) {
        	r.tasks = {};
            tasks.forEach(task => {
            	delete task.type;
                r.tasks[task.name] = task;
            });
        }

        const rules = content.filter(c => c.type === "entry");
        if(rules.length) {
        	r.rules = rules.map(r => {
            	delete r.type;
            	return r;
            });
        }

    	return r;
    }

aclContent = (aclFields / aclTasks / aclEntry)

aclFields "acl fields"
	= ws "fields" ws fieldName:string
    begin_object
    head:propName tail:(value_separator n:propName{return n;})*
    end_object
    {
    	const v = [head];
        if(tail && tail.length) {
        	v.push.apply(v, tail);
        }
    	return {type: "fields", name:fieldName, fields:v};
    }

aclTasks "acl tasks"
	= ws "tasks" ws fieldName:string
    begin_object
    head:string tail:(value_separator n:string{return n;})*
    end_object
    {
    	const v = [head];
        if(tail && tail.length) {
        	v.push.apply(v, tail);
        }
    	return {type: "tasks", name:fieldName, tasks:v};
    }

aclTarget "acl target"
	= "<" chars:[A-Za-z0-9-]* ">"
    {
        return chars.join("");
    }

aclEntry "acl entry"
	= ws permission:("allow"/"deny") ws target:aclTarget ws actions:aclAccessList
      grouping:aclAccessTargetSpecifier? condition:aclCondition?
   	{
    	const r = {type:"entry", permission:permission, target:target, actions:actions};
    	if(grouping) {
        	r.grouping = grouping;
        }
        if(condition) {
        	r.condition = condition;
        }
    	return r;
    }

aclAccessList "acl access list"
	= ws "[" head:aclAccessType tail:(value_separator t:aclAccessType {return t;})* "]" ws
    {
    	const rules = [head];
        if(tail && tail.length) {
        	rules.push.apply(rules, tail);
        }
    	return rules;
    }

aclAccessType "acl access type"
	= ws type:("read" / "write" / "task"
    			/ "access:own" / "access:all"
                / "destroy" / "create") ws
    {
    	let t = type.split(":");
        const r = {type:t[0]};
        if(t.length > 1) {
        	r.restriction = t[1];
        }
    	return r;
    }

aclAccessTargetSpecifier "acl access target specifier"
	= ws "on" ws target:string
    { return target; }

aclCondition "acl condition"
	= ws "where" ws condition:Condition
    {
    	return condition;
    }


// Mapping

mapping "mapping"
	= ws "mapping" ws mappingName:string ws "on" ws enumType:propName
    begin_object
    head:mappingEntry?
    tail:("," v:mappingEntry {return v})*
    end_object
    {
    	const mappings = [];
       	if(head) {
        	mappings.push(head);
        	if(tail && tail.length) {
            	mappings.push.apply(mappings, tail);
            }
        }
    	return {type:"mapping", name:mappingName, enum:enumType, mappings:mappings};
    }

mappingEntry "mapping entry"
	= ws name:propName ws "=>" ws value:string ws
    {
    	return {enumValue:name, value};
    }
