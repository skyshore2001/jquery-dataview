# jquery-dataview 数据视图插件 - 数据填充与视图更新利器

jquery-dataview是一个超轻量的jquery插件，用于对DOM进行数据填充与更新，也很适合根据DOM模板创建对象。

与一些纯模板库（例如juicer）相比，它不仅能提供根据模板填入数据、支持循环、支持条件创建等功能，还支持绑定事件，最重要的是，在创建完DOM对象后，这些对象（称为数据视图）关联到原始数据，修改数据后，相应的视图也得以更新。

与一些支持数据驱动或MVVM模式的库（例如vue）相比，它没有去做数据绑定等高级自动化的机制，那涉及诸多复杂逻辑，比如属性依赖管理等，使用者如果了解不多，很可能写出低效的代码，或触发一连串未曾预料的后果。比如在一个列表中，只更新其中一条数据的某个属性，就可能导致刷新整个列表，甚至发起与后端的多次不必要交互。

jquery-dataview插件的设计理念是简单而灵活，它不采用极其复杂的自动化更新机制，而是允许人为精准控制更新时机与更新区域；同时，它最小化并压缩后仅2K不到，很适合在移动端开发使用。

下面介绍几个入门例子。

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

它会递归遍历所有带name属性的结点，如`<span name="id"></span>`会用`customer.id`为其赋值。

JS修改数据后，可无参数调用dataview来刷新显示：

```javascript
	customer.name = "SAP China";
	$(".customer").dataview();
```

获取DOM绑定的数据：

```javascript
	var data = $(".customer").dataview('getData');
```

## 为模板填充数据

这个例子在项目中更加常用，展示根据模板创建DOM、填充数据并插入文档中。

HTML: 客户列表

```html
	<div id="divCustomers"></div>

	<style type="text/template" id="tplCustomer">
		<div class="customer">
			<p>id=<span name="id"></span></p>
			<p>name=<span name="name"></span></p>
		</div>
	</style>
```

JS: 根据“客户”模板创建客户并插入列表中。

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

## 循环创建、条件创建、条件显示

子对象数组可以以`dv-for`属性来指定循环展开。

dv-if及dv-show属性：根据该属性的值计算是否创建或显示该结点。

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

上例中，由data.customers子数组循环创建DOM，其中`id=1`的customer没有创建，因为不满足`dv-if="id>=1000"`的条件；而`id=2001`的那个customer由于不满足`dv-show="id<=2000"`的条件，因而id没有显示出来。

## 指定事件

dataview不仅绑定数据，还可以用`dv-on`属性绑定事件，在JS中使用选项`events`与其对应。

```html
	<div dv-on="liOrder_click"></div>
```

事件名必须是`{对象名}_{事件名}`的格式。
上面代码最终相当于调用`jo.on("click", data, liOrder_click)`，绑定的数据会通过event.data传递给回调函数，因而在回调函数中处理数据特别方便。

用到的函数必须通过`events`选项定义：
```javascript
	var events = {
		liOrder_click: function (ev) {
			var order = ev.data; // 等同于 $(this).dataview('getData');
			// ...
		}
	};
	jo.dataview(data, {events: events});
```
与直接使用原生支持的onclick属性相比，使用dv-on属性的好处是事件处理函数不必是全局函数，而且事件处理函数的参数`ev.data`即是DOM绑定的数据，非常方便。

## 多层嵌套的数据

对复杂的多层次嵌套数据的支持是dataview插件的一大亮点。
通过精巧的设计，它不仅做到填充数据时特别简单，而且在更新数据时，允许自由地更新任意区域，行为易懂且效率很高。

JS数据：一个customer-客户，它包含id, name等普通属性，包含一个子对象addr-地址信息，还包含一个子对象数组orders-订单。
每个订单中，又包含一个子对象数组items-物料信息。

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

HTML数据视图，展示客户、订单、物料三层数据：

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
					</li>
				</ul>
			</li>
		</ul>
	</div>
```

JS: 

```javascript
	$(".customer").dataview(customer);

	// 更新一些数据
	++ customer.orders[0].amount;
	customer.orders[0].items[0].name += " - updated";

	// 视图局部更新：只更新一个item
	var jitem = $(".customer .order:first .item:first");
	jitem.dataview();

	// 取DOM绑定的item数据
	var itemData = jitem.dataview('getData');
	// 通过 $parent 取上层数据
	var orderData = itemData.$parent;
	var data = orderData.$parent;

	// 视图局部更新：只更新一个order:
	$(".customer .order:first").dataview();

	// 全部更新
	$(".customer").dataview();
```

上面只是多层次数据的简单的用法介绍，通过子对象的`$parent`属性可以取到上次对象。
实际使用时，常会把这些特性同计算属性、事件绑定结合起来，你会发现它会让取数据和更新视图的代码简单、灵活、易懂。

## 结语

作为一个超轻量级的具有数据驱动视图概念的库，推荐在项目中使用，可为让你的代码更清晰简练。
上面只是一个简单的介绍，更多如计算属性等功能可参考它的文档。

附github地址（其中有源码、文档和示例代码）：

	https://github.com/skyshore2001/jquery-dataview

