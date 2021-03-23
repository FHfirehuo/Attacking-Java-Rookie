# JVM指令集整理

---
 指令码|助记符 | 说明
 
| 指令码 | 助记符 | 说明 |
| --- | --- | --- |
| 0×00 | nop | 什么都不做 |
| 0×01 | aconst_null | 将null推送至栈顶 |
| 0×02 | iconst_m1 | 将int型-1推送至栈顶 |
| 0×03 | iconst_0 | 将int型0推送至栈顶 |
| 0×04 | iconst_1 | 将int型1推送至栈顶 |
| 0×05 | iconst_2 | 将int型2推送至栈顶 |
| 0×06 | iconst_3 | 将int型3推送至栈顶 |
| 0×07 | iconst_4 | 将int型4推送至栈顶 |
| 0×08 | iconst_5 | 将int型5推送至栈顶 |
| 0×09 | lconst_0 | 将long型0推送至栈顶 |
| 0x0a | lconst_1 | 将long型1推送至栈顶 |
| 0x0b | fconst_0 | 将float型0推送至栈顶 |
| 0x0c | fconst_1 | 将float型1推送至栈顶 |
| 0x0d | fconst_2 | 将float型2推送至栈顶 |
| 0x0e | dconst_0 | 将double型0推送至栈顶 |
| 0x0f | dconst_1 | 将double型1推送至栈顶 |
| 0×10 | bipush | 将单字节的常量值(-128~127)推送至栈顶 |
| 0×11 | sipush | 将一个短整型常量值(-32768~32767)推送至栈顶 |
| 0×12 | ldc | 将int, float或String型常量值从常量池中推送至栈顶 |
| 0×13 | ldc_w | 将int, float或String型常量值从常量池中推送至栈顶（宽索引） |		
| 0×14 | ldc2_w | 将long或double型常量值从常量池中推送至栈顶（宽索引） |
| 0×15 | iload | 将指定的int型本地变量推送至栈顶 |
| 0×16 | lload | 将指定的long型本地变量推送至栈顶 |
| 0×17 | fload | 将指定的float型本地变量推送至栈顶 |
| 0×18 | dload | 将指定的double型本地变量推送至栈顶 |
| 0×19 | aload | 将指定的引用类型本地变量推送至栈顶 |
| 0x1a | iload_0 | 将第0个int型本地变量推送至栈顶 |
| 0x1b | iload_1 | 将第1个int型本地变量推送至栈顶 |
| 0x1c | iload_2 | 将第2个int型本地变量推送至栈顶 |
| 0x1d | iload_3 | 将第3个int型本地变量推送至栈顶 |
| 0x1e | lload_0 | 将第0个long型本地变量推送至栈顶 |
| 0x1f | lload_1 | 将第1个long型本地变量推送至栈顶 |	
| 0×20 | lload_2 | 将第2个long型本地变量推送至栈顶 |
| 0×21 | lload_3 | 将第3个long型本地变量推送至栈顶 |
| 0×22 | fload_0 | 将第0个float型本地变量推送至栈顶 |
| 0×23 | fload_1 | 将第1个float型本地变量推送至栈顶 |
| 0×24 | fload_2 | 将第2个float型本地变量推送至栈顶 |
| 0×25 | fload_3 | 将第3个float型本地变量推送至栈顶 |
| 0×26 | dload_0 | 将第0个double型本地变量推送至栈顶 |
| 0×27 | dload_1 | 将第1个double型本地变量推送至栈顶 |
| 0×28 | dload_2 | 将第2个double型本地变量推送至栈顶 |
| 0×29 | dload_3 | 将第3个double型本地变量推送至栈顶 |
| 0x2a | aload_0 | 将第0个引用类型本地变量推送至栈顶 |
| 0x2b | aload_1 | 将第1个引用类型本地变量推送至栈顶 |
| 0x2c | aload_2 | 将第2个引用类型本地变量推送至栈顶 |
| 0x2d | aload_3 | 将第3个引用类型本地变量推送至栈顶 |
| 0x2e | iaload | 将int型数组指定索引的值推送至栈顶 |
| 0x2f | laload | 将long型数组指定索引的值推送至栈顶 |
| 0×30 | faload | 将float型数组指定索引的值推送至栈顶 |
| 0×31 | daload | 将double型数组指定索引的值推送至栈顶 |
| 0×32 | aaload | 将引用型数组指定索引的值推送至栈顶 |
| 0×33 | baload | 将boolean或byte型数组指定索引的值推送至栈顶 |
| 0×34 | caload | 将char型数组指定索引的值推送至栈顶 |
| 0×35 | saload | 将short型数组指定索引的值推送至栈顶 |
| 0×36 | 	istore | 将栈顶int型数值存入指定本地变量 |
| 0×37 | lstore | 将栈顶long型数值存入指定本地变量 |		
| 0×38 | fstore | 将栈顶float型数值存入指定本地变量 |
| 0×39 | dstore | 将栈顶double型数值存入指定本地变量 |
| 0x3a | astore | 将栈顶引用型数值存入指定本地变量 |
| 0x3b | istore_0 | 将栈顶int型数值存入第0个本地变量 |
| 0x3c | istore_1 | 将栈顶int型数值存入第1个本地变量 |
| 0x3d | istore_2 | 将栈顶int型数值存入第2个本地变量 |
| 0x3e | istore_3 | 将栈顶int型数值存入第3个本地变量 |		
| 0x3f | lstore_0 | 将栈顶long型数值存入第0个本地变量 |
|0×40 | lstore_1 | 将栈顶long型数值存入第1个本地变量 |
| 0×41| lstore_2 | 将栈顶long型数值存入第2个本地变量 |
| 0×42 | lstore_3 | 将栈顶long型数值存入第3个本地变量 |
| 0×43 | fstore_0 | 将栈顶float型数值存入第0个本地变量 |
| 0×44 | fstore_1 | 将栈顶float型数值存入第1个本地变量 |
| 0×45 | fstore_2 | 将栈顶float型数值存入第2个本地变量 |
| 0×46 | fstore_3 | 将栈顶float型数值存入第3个本地变量 |
| 0×47 | dstore_0 | 将栈顶double型数值存入第0个本地变量 |
| 0×48 | dstore_1 | 将栈顶double型数值存入第1个本地变量 |
| 0×49 | dstore_2 | 将栈顶double型数值存入第2个本地变量 |
| 0x4a | dstore_3 | 将栈顶double型数值存入第3个本地变量 |
|0x4b | astore_0 | 将栈顶引用型数值存入第0个本地变量 |
| 0x4c | astore_1 | 将栈顶引用型数值存入第1个本地变量 |
| 0x4d | astore_2 | 将栈顶引用型数值存入第2个本地变量 |
| 0x4e | astore_3 | 将栈顶引用型数值存入第3个本地变量 |
| 0x4f | iastore	 | 将栈顶int型数值存入指定数组的指定索引位置 |
|0×50 | lastore | 将栈顶long型数值存入指定数组的指定索引位置 |
| 0×51 | fastore | 将栈顶float型数值存入指定数组的指定索引位置 |
| 0×52 | dastore | 将栈顶double型数值存入指定数组的指定索引位置 |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0×53	aastore	将栈顶引用型数值存入指定数组的指定索引位置
0×54	bastore	将栈顶boolean或byte型数值存入指定数组的指定索引位置
0×55	castore	将栈顶char型数值存入指定数组的指定索引位置
0×56	sastore	将栈顶short型数值存入指定数组的指定索引位置
0×57	pop	将栈顶数值弹出 (数值不能是long或double类型的)
0×58	pop2	将栈顶的一个（long或double类型的)或两个数值弹出（其它）
0×59	dup	复制栈顶数值并将复制值压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x5a	dup_x1	复制栈顶数值并将两个复制值压入栈顶
0x5b	dup_x2	复制栈顶数值并将三个（或两个）复制值压入栈顶
0x5c	dup2	复制栈顶一个（long或double类型的)或两个（其它）数值并将复制值压入栈顶
0x5d	dup2_x1	<待补充>
0x5e	dup2_x2	<待补充>
0x5f	swap	将栈最顶端的两个数值互换(数值不能是long或double类型的)
0×60	iadd	将栈顶两int型数值相加并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0×61	ladd	将栈顶两long型数值相加并将结果压入栈顶
0×62	fadd	将栈顶两float型数值相加并将结果压入栈顶
0×63	dadd	将栈顶两double型数值相加并将结果压入栈顶
0×64	isub	将栈顶两int型数值相减并将结果压入栈顶
0×65	lsub	将栈顶两long型数值相减并将结果压入栈顶
0×66	fsub	将栈顶两float型数值相减并将结果压入栈顶
0×67	dsub	将栈顶两double型数值相减并将结果压入栈顶
0×68	imul	将栈顶两int型数值相乘并将结果压入栈顶
0×69	lmul	将栈顶两long型数值相乘并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x6a	fmul	将栈顶两float型数值相乘并将结果压入栈顶
0x6b	dmul	将栈顶两double型数值相乘并将结果压入栈顶
0x6c	idiv	将栈顶两int型数值相除并将结果压入栈顶
0x6d	ldiv	将栈顶两long型数值相除并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x6e	fdiv	将栈顶两float型数值相除并将结果压入栈顶
0x6f	ddiv	将栈顶两double型数值相除并将结果压入栈顶
0×70	irem	将栈顶两int型数值作取模运算并将结果压入栈顶
0×71	lrem	将栈顶两long型数值作取模运算并将结果压入栈顶
0×72	frem	将栈顶两float型数值作取模运算并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0×73	drem	将栈顶两double型数值作取模运算并将结果压入栈顶
0×74	ineg	将栈顶int型数值取负并将结果压入栈顶
0×75	lneg	将栈顶long型数值取负并将结果压入栈顶
0×76	fneg	将栈顶float型数值取负并将结果压入栈顶
0×77	dneg	将栈顶double型数值取负并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0×78	ishl	将int型数值左移位指定位数并将结果压入栈顶
0×79	lshl	将long型数值左移位指定位数并将结果压入栈顶
0x7a	ishr	将int型数值右（符号）移位指定位数并将结果压入栈顶
0x7b	lshr	将long型数值右（符号）移位指定位数并将结果压入栈顶
0x7c	iushr	将int型数值右（无符号）移位指定位数并将结果压入栈顶
0x7d	lushr	将long型数值右（无符号）移位指定位数并将结果压入栈顶
0x7e	iand	将栈顶两int型数值作“按位与”并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x7f	land	将栈顶两long型数值作“按位与”并将结果压入栈顶
0×80	ior	将栈顶两int型数值作“按位或”并将结果压入栈顶
0×81	lor	将栈顶两long型数值作“按位或”并将结果压入栈顶
0×82	ixor	将栈顶两int型数值作“按位异或”并将结果压入栈顶
0×83	lxor	将栈顶两long型数值作“按位异或”并将结果压入栈顶
0×84	iinc	将指定int型变量增加指定值，可以有两个变量，分别表示index, const，index指第index个int型本地变量，const增加的值
0×85	i2l	将栈顶int型数值强制转换成long型数值并将结果压入栈顶
0×86	i2f	将栈顶int型数值强制转换成float型数值并将结果压入栈顶
0×87	i2d	将栈顶int型数值强制转换成double型数值并将结果压入栈顶
0×88	l2i	将栈顶long型数值强制转换成int型数值并将结果压入栈顶
0×89	l2f	将栈顶long型数值强制转换成float型数值并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x8a	l2d	将栈顶long型数值强制转换成double型数值并将结果压入栈顶
0x8b	f2i	将栈顶float型数值强制转换成int型数值并将结果压入栈顶
0x8c	f2l	将栈顶float型数值强制转换成long型数值并将结果压入栈顶
0x8d	f2d	将栈顶float型数值强制转换成double型数值并将结果压入栈顶
0x8e	d2i	将栈顶double型数值强制转换成int型数值并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x8f	d2l	将栈顶double型数值强制转换成long型数值并将结果压入栈顶
0×90	d2f	将栈顶double型数值强制转换成float型数值并将结果压入栈顶
0×91	i2b	将栈顶int型数值强制转换成byte型数值并将结果压入栈顶
0×92	i2c	将栈顶int型数值强制转换成char型数值并将结果压入栈顶
0×93	i2s	将栈顶int型数值强制转换成short型数值并将结果压入栈顶
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0×94	lcmp	比较栈顶两long型数值大小，并将结果（1，0，-1）压入栈顶
0×95	fcmpl	比较栈顶两float型数值大小，并将结果（1，0，-1）压入栈顶；当其中一个数值为NaN时，将-1压入栈顶
0×96	fcmpg	比较栈顶两float型数值大小，并将结果（1，0，-1）压入栈顶；当其中一个数值为NaN时，将1压入栈顶
0×97	dcmpl	比较栈顶两double型数值大小，并将结果（1，0，-1）压入栈顶；当其中一个数值为NaN时，将-1压入栈顶
0×98	dcmpg	比较栈顶两double型数值大小，并将结果（1，0，-1）压入栈顶；当其中一个数值为NaN时，将1压入栈顶
0×99	ifeq	当栈顶int型数值等于0时跳转
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x9a	ifne	当栈顶int型数值不等于0时跳转
0x9b	iflt	当栈顶int型数值小于0时跳转
0x9c	ifge	当栈顶int型数值大于等于0时跳转
0x9d	ifgt	当栈顶int型数值大于0时跳转
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0x9e	ifle	当栈顶int型数值小于等于0时跳转
0x9f	if_icmpeq	比较栈顶两int型数值大小，当结果等于0时跳转
0xa0	if_icmpne	比较栈顶两int型数值大小，当结果不等于0时跳转
0xa1	if_icmplt	比较栈顶两int型数值大小，当结果小于0时跳转

| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0xa2	if_icmpge	比较栈顶两int型数值大小，当结果大于等于0时跳转
0xa3	if_icmpgt	比较栈顶两int型数值大小，当结果大于0时跳转
0xa4	if_icmple	比较栈顶两int型数值大小，当结果小于等于0时跳转
0xa5	if_acmpeq	比较栈顶两引用型数值，当结果相等时跳转
0xa6	if_acmpne	比较栈顶两引用型数值，当结果不相等时跳转
0xa7	goto	无条件跳转
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0xa8	jsr	跳转至指定16位offset位置，并将jsr下一条指令地址压入栈顶
0xa9	ret	返回至本地变量指定的index的指令位置（一般与jsr, jsr_w联合使用）
0xaa	tableswitch	用于switch条件跳转，case值连续（可变长度指令）
0xab	lookupswitch	用于switch条件跳转，case值不连续（可变长度指令）
0xac	ireturn	从当前方法返回int
0xad	lreturn	从当前方法返回long
0xae	freturn	从当前方法返回float
0xaf	dreturn	从当前方法返回double
0xb0	areturn	从当前方法返回对象引用
0xb1	return	从当前方法返回void
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
0xb2	getstatic	获取指定类的静态域，并将其值压入栈顶
0xb3	putstatic	为指定的类的静态域赋值
0xb4	getfield	获取指定类的实例域，并将其值压入栈顶
0xb5	putfield	为指定的类的实例域赋值
0xb6	invokevirtual	调用实例方法
0xb7	invokespecial	调用超类构造方法，实例初始化方法，私有方法
0xb8	invokestatic	调用静态方法
0xb9	invokeinterface	调用接口方法
0xba	–
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| a | b | c |
| 0xbb | new	 | 创建一个对象，并将其引用值压入栈顶 |
| 0xbc |newarray| 创建一个指定原始类型（如int, float, char…）的数组，并将其引用值压入栈顶 |
| 0xbd | anewarray | 创建一个引用型（如类，接口，数组）的数组，并将其引用值压入栈顶 |
| 0xbe | arraylength | 获得数组的长度值并压入栈顶 |
| 0xbf | athrow | 将栈顶的异常抛出 |
| 0xc0 | checkcast	 | 检验类型转换，检验未通过将抛出ClassCastException |	
|0xc1 | instanceof | 检验对象是否是指定的类的实例，如果是将1压入栈顶，否则将0压入栈顶|
| 0xc2 | monitorenter | 获得对象的锁，用于同步方法或同步块 |
| 0xc3 | monitorexit | 释放对象的锁，用于同步方法或同步块 |
| 0xc4 | wide | 当本地变量的索引超过255时使用该指令扩展索引宽度。 |
| 0xc5 | multianewarray | create a new array of dimensions dimensions with elements of type identified by class reference in constant pool index (indexbyte1 << 8 + indexbyte2); the sizes of each dimension  is identified by count1, [count2, etc.]|
| a | b | c |
| a | b | c |
		
		
		
0xc6	ifnull	if value is null, branch to instruction at branchoffset (signed short constructed from unsigned bytes branchbyte1 << 8 + branchbyte2)
0xc7	ifnonnull	if value is not null, branch to instruction at branchoffset (signed short constructed from unsigned bytes branchbyte1 << 8 + branchbyte2)
0xc8	goto_w	goes to another instruction at branchoffset (signed int constructed from unsigned bytes branchbyte1 << 24 + branchbyte2 << 16 + branchbyte3 << 8 + branchbyte4)
0xc9	jsr_w	jump to subroutine at branchoffset (signed int constructed from unsigned bytes branchbyte1 << 24 + branchbyte2 << 16 + branchbyte3 << 8 + branchbyte4) and place the return address on the stack
0xca	breakpoint	reserved for breakpoints in Java debuggers; should not appear in any class file
0xcb-0xfd	未命名	these values are currently unassigned for opcodes and are reserved for future use
0xfe	impdep1	reserved for implementation-dependent operations within debuggers; should not appear in any class file
0xff	impdep2	reserved for implementation-dependent operations within debuggers; should not appear in any class file
有了以上指令集表，那么在查看字节码就方便多了。

对应英文 => https://en.wikipedia.org/wiki/Java_bytecode_instruction_listings

 

来几个sample:

切换到文件的对应的目录

sample1

java

 
1

2

3


 
public void sample1(){

int num = 5;

}

javap -c 查看字节码

 
1

2

3

4

5


 
public void sample1();

Code:

0: iconst_5

1: istore_1

2: return

解释

 
1

2

3


 
iconst_5 //将int型5推送至栈顶

istore_1 //将栈顶int型数值存入第1个本地变量

return //从当前方法返回void

sample2

java

 
1

2

3


 
public int sample2(int a, int b) {

return a + b;

}

字节码及解释

 
1

2

3

4

5

6


 
public int sample2(int, int);

Code:

0: iload_1 //将第1个int型本地变量推送至栈顶

1: iload_2 //将第2个int型本地变量推送至栈顶

2: iadd //将栈顶两int型数值相加并将结果压入栈顶

3: ireturn //从当前方法返回int

sample3

java
稍稍复杂点


 
1

2

3

4

5

6

7


 
public float sample3() {

float num = 0;

for (int i = 0; i < 5; i++) {

num *= i;

}

return num;

}

字节码及解释

 
1

2

3

4

5

6

7

8

9

10

11

12

13

14

15

16

17

18

19

20


 
public float sample3();

Code:

0: fconst_0 //将float型0推送至栈顶

1: fstore_1 //将栈顶float型数值存入第1个本地变量

2: iconst_0 //将int型0推送至栈顶，也就是for循环中的i = 0

3: istore_2 //将栈顶int型数值存入第2个本地变量

4: iload_2 //将第2个int型本地变量推送至栈顶

5: iconst_5 //将int型5推送至栈顶，也就是for循环中的 最大值5

6: if_icmpge 20 //比较栈顶两int型数值大小，当结果大于等于0时跳转，

//也就是比较0是否大于等于5，(cpmge指compare larger equals)，如果是跳转到到第20条指令

9: fload_1 //将第1个float型本地变量推送至栈顶，也就是变量num

10: iload_2 //将第2个int型本地变量推送至栈顶，也就是for循环中的变量i

11: i2f //int型强转为float型，也就是把变量i强转成float

12: fmul //将栈顶两float型数值相乘并将结果压入栈顶，也就是i与num相乘

13: fstore_1 //将栈顶float型数值存入第1个本地变量，也就是之前i与num的乘积

14: iinc 2, 1 //将指定int型变量增加指定值，将第2个int型本地变量增加1，

//可以看到，第2个int型本地变量就是之前的变量i

17: goto 4 //无条件跳转到指令4，实现循环效果

20: fload_1 //将第1个float型本地变量推送至栈顶

21: freturn //从当前方法返回float

 
public class MainActivity extends AppCompatActivity {
    public MainActivity() {
    }
 
    public int calc() {
        int a = 500;
        int b = 200;
        int c = 50;
        return (a + b) / c;
    }
 
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        this.setContentView(2130968603);
    }
}
他的字节码文件 javap -c

 

public class zew.testdemo.MainActivity extends android.support.v7.app.AppCompatActivity {
  public zew.testdemo.MainActivity();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method android/support/v7/app/AppCompatActivity."<init>":()V
       4: return
 
  public int calc();
    Code:
       0: sipush        500
       3: istore_1
       4: sipush        200
       7: istore_2
       8: bipush        50
      10: istore_3
      11: iload_1
      12: iload_2
      13: iadd
      14: iload_3
      15: idiv
      16: ireturn
 
  protected void onCreate(android.os.Bundle);
    Code:
       0: aload_0
       1: aload_1
       2: invokespecial #2                  // Method android/support/v7/app/AppCompatActivity.onCreate:(Landroid/os/Bundle;)V
       5: aload_0
       6: ldc           #4                  // int 2130968603
       8: invokevirtual #5                  // Method setContentView:(I)V
      11: return
}
这里额外要说的就是，在非静态方法中，aload_0 表示对this的操作，在static 方法中，aload_0表示对方法的第一参数的操作。
————————————————
版权声明：本文为CSDN博主「遥望江南2009」的原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/u012070360/article/details/81624854
