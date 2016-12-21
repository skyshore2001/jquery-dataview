@module jquery-dataview 数据视图

jquery插件，用于对DOM进行数据填充与更新，也很适合根据DOM模板创建对象。

特点：

- 允许人为精准控制更新区域，可以更新dataview对象或其任意子对象
- 对多层次数据支持良好，可对子对象数组用vd-for标签展开，并自动绑定到子对象数据。

## 为DOM对象填充数据

例：对一个DOM赋值

HTML:

```html
	<div class="customer">
		<p>id=<span name="id"></span></p>
		<p>name=<span name="name"></span></p>
	</div>
```

JS填充数据:

```javascript
	var customer = { id: 1001, name: "SAP AG" };
	$(".customer").dataview(customer);
```

递归遍历所有带name属性的结点，如`<span name="id"></span>`会用`customer.id`为其赋值。

JS修改数据后，可无参数调用dataview来刷新显示：

```javascript
	customer.name = "SAP China";
	$(".customer").dataview();
```

取DOM绑定的数据：

```javascript
	var data = $(".customer").dataview('getData');
```

上面是调用getData方法的形式，在文档中表示为

	@fn getData()

如果有参数，则加到调用名后面。

## 为模板填充数据

HTML:

```html
	<div id="divCustomers"></div>

	<style type="text/template" id="tplCustomer">
		<div class="customer">
			<p>id=<span name="id"></span></p>
			<p>name=<span name="name"></span></p>
		</div>
	</style>
```

JS:

```javascript
	var customers = [
		{ id: 1001, name: "SAP AG" },
		{ id: 2001, name: "Oracle CO" }
	];
	var jtplCustomer = $($("#tplCustomer").html());
	var jparent = $("#divCustomers");
	$.each(customers, function (i, customer) {
		jtplCustomer.clone()
			.dataview(customer)
			.appendTo(jparent);
	});
```

## 计算属性

在JS中通过`props`选项指定属性的计算函数。

HTML:

```html
	<div class="customer">
		<p>id=<span name="id"></span></p>
		<p>fullname=<span name="fullname"></span></p>
	</div>
```

JS: 定义fullname属性

```javascript
	var customer = { id: 1001, name: "SAP AG" };
	var opt = {
		props: {
			fullname: function () {
				// this表示当前层次数据
				return this.id + " - " + this.name;
			}
		}
	};
	$(".customer").dataview(customer, opt);

	// 更新：
	customer.name = "SAP China";
	$(".customer").dataview();
	// fullname也得到更新.
```

在初始化时，做为计算属性的函数会自动添加到相应的数据上。
在更新视图时，如果发现name属性指定的是一个函数，则以调用后的值来填充。

## 访问子对象

假如有数据：

```javascript
	var customer = {
		id: 1001, 
		name: "SAP AG",
		addr: {country: "CN", city: "Shanghai"}
	};
```

这里`addr`是`customer`的子对象，可以这样来显示`customer.addr.city`:

```html
	<span name="addr.city"></span>
```

求值时，以 `eval("data." + name)` 的方式获得值。（未使用with机制计算以免降低性能）

## 循环创建、条件创建、条件显示

子对象数组可以以`dv-for`属性来指定循环展开，每复制一个DOM，都会绑定数据到相应的子对象上。

dv-if及dv-show属性：根据该属性的值计算是否保留该结点，或显示该结点。

例：使用dv-for, dv-if, dv-show等标签：

HTML:

```html
	<div id="divCustomers">
		<div dv-for="customers" dv-if="id>=1000" class="customer">
			<li>
				<span dv-show="id<=2000">id=<span name="id"></span></span>
				name=<span name="name"></span>
			</li>
		</div>
	</div>
```

JS:

```javascript
	var data = {
		customers: [
			{ id: 1, name: "Olive CO" },
			{ id: 1001, name: "SAP AG" },
			{ id: 2001, name: "Oracle CO" }
		]
	};
	$("#divCustomers").dataview(data);
```

结果：

- dv-for指定了用于循环的数组数据，由data.customers数组总共生成两项，id=1的那项因不满足dv-if="id>1000"的条件没有创建。
- dv-show指定了显示出来的条件，因而id=2001的项未显示出id。

`dv-for`可以在顶层出现，这时dataview返回的是一个新的DOM数组，与传入的jo会不同。

```javascript
	jo1 = jo.dataview(data); // jo1与jo可能不同。
```

dv-if及dv-show属性中指定一个条件表达式，它可以比name中指定的内容要复杂，它的计算原理是：

```javascript
	with(data) { eval(val); }
```

## 指定事件

在HTML中使用`dv-on`属性指定事件，在JS中使用选项`events`与其对应。

```html
	<div dv-on="liOrder_click"></div>
```

上面代码定义了`jo.on("click", data, liOrder_click)`，所有用到的函数必须通过`events`选项定义：

```javascript
	var events = {
		liOrder_click: function (ev) {
			var order = ev.data; // 等同于 $(this).dataview('getData');
			// ...
		}
	};
	jo.dataview(data, {events: events});
```

可以指定多个事件，用逗号","隔开：

```html
	<input dv-on="txtName_change,txtName_keydown"></div>
```

HTML:

```html
	<form class="customer" dv-on="frmCustomer_submit">
		<p>id=<span name="id"></span></p>
		<input dv-on="txtName_change,txtName_keydown" name="name">
		<button dv-on="btnUpdate_click">更新</button>
	</form>
```

上面为form指定了submit事件，dv-on的值要求是`{domName}_{eventName}`的格式，domName可任意起名，eventName必须是合法的事件名。

JS:

```javascript
	var events = {
		frmCustomer_submit: function (ev) {
			alert(arguments.callee.name);
			console.log("cancel submit");
			return false;
		},
		txtName_change: function (ev) {
			alert(arguments.callee.name);
		},
		txtName_keydown: function (ev) {
			console.log(arguments.callee.name);
		},
		btnUpdate_click: function (ev) {
			alert(arguments.callee.name);
		}
	};
	var opt = {
		events: events
	};

	var customer = { id: 1001, name: "SAP AG" };
	$(".customer").dataview(customer, opt);
```

与直接使用onclick属性相比，用dv-on的好处有：

- 事件处理函数不必是全局函数。
- 事件处理函数的参数`ev.data`即是DOM绑定的数据，使用很方便。

## 获取数据

```javascript
	// 获取DOM关联的数据
	var data = jo.dataview('getData');

	//TODO:
	// 获取用户输入的数据
	var formData = jo.dataview('getFormData');
	// 获取用户输入的数据与原始数据差异部分。
	var formDataDiff = jo.dataview('getFormData', {diff: true});
```

## 多层嵌套的数据

每个对象数组是一个嵌套层次。

- 可通过数据的 `$parent` 属性访问上层数据。
- 支持子对象的计算字段
- 不必更新根对象，可以指定更新任意子对象的数据视图。

示例：数据模型如下：

	customer = {id, name, %addr={country, city}, @orders }
	@orders = {id, amount, @items={id, name} }

customer是0层，@orders是第1层，@items是第2层; 注意：addr下的字段与customer是当作同一层的。

JS数据：

```javascript
	var customer = {
		id: 1001, 
		name: "SAP AG",
		addr: {country: "CN", city: "Shanghai"},
		orders: [
			{id: 1, amount: 9000, items: [
				{id: 101, name: "item 101"},
				{id: 102, name: "item 102"}
			]},
			{id: 2, amount: 11000, items: [
				{id: 201, name: "item 201"}
			]}
		]
	}
```

HTML数据视图：

```html
	<div class="customer">
		<p> name: <span name="name"></span>  </p>
		<p> addr: <span name="addr.country"></span> / <span name="addr.city"></span> </p>
		<ul>
			<li dv-for="orders" class="order">
				<p>order id=<span name="id"></span>, amount=<span name="amount"></span></p>
				<ul>
					<li dv-for="items" class="item">
						<p>item id=<span name="id"></span></p>
						<p>item name=<span name="name"></span></p>
						<p>fullname=<span name="fullname"></span></p>
					</li>
				</ul>
			</li>
		</ul>
	</div>
```

注意：

- 可以使用`addr.country`的格式指定数据源。

JS:

```javascript
	var itemOpt = {
		props: {
			fullname: function () {
				var order = this.$parent;
				var customer = order.$parent;
				return customer.name + " - " + this.name;
			}
		}
	};
	var orderOpt = {
		children: {items: itemOpt}
	};
	var customerOpt = {
		children: {orders: orderOpt}
	};
	$(".customer").dataview(customer, customerOpt);

	// 局部更新：只更新一个item
	customer.orders[0].items[0].name += " - updated";
	$(".customer .order:first .item:first").dataview();

	// 只更新一个order:
	++ customer.orders[0].amount;
	customer.orders[0].items[0].name += " - updated2";
	$(".customer .order:first").dataview();

	// 全部更新
	$(".customer").dataview();
```

## 常见错误

生成的DOM有混乱：常常由标签未闭合导致