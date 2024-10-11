
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	3a013103          	ld	sp,928(sp) # 8000b3a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	1761                	addi	a4,a4,-8 # 200bff8 <_entry-0x7dff4008>
    8000003a:	6318                	ld	a4,0(a4)
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	0000b717          	auipc	a4,0xb
    80000054:	3b070713          	addi	a4,a4,944 # 8000b400 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	4ce78793          	addi	a5,a5,1230 # 80006530 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd1d7f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e2678793          	addi	a5,a5,-474 # 80000ed2 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    8000010a:	04c05663          	blez	a2,80000156 <consolewrite+0x56>
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	f44e                	sd	s3,40(sp)
    80000112:	f052                	sd	s4,32(sp)
    80000114:	ec56                	sd	s5,24(sp)
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	846080e7          	jalr	-1978(ra) # 80002970 <either_copyin>
    80000132:	03550463          	beq	a0,s5,8000015a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	7e4080e7          	jalr	2020(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    8000014c:	74e2                	ld	s1,56(sp)
    8000014e:	79a2                	ld	s3,40(sp)
    80000150:	7a02                	ld	s4,32(sp)
    80000152:	6ae2                	ld	s5,24(sp)
    80000154:	a039                	j	80000162 <consolewrite+0x62>
    80000156:	4901                	li	s2,0
    80000158:	a029                	j	80000162 <consolewrite+0x62>
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	79a2                	ld	s3,40(sp)
    8000015e:	7a02                	ld	s4,32(sp)
    80000160:	6ae2                	ld	s5,24(sp)
  }

  return i;
}
    80000162:	854a                	mv	a0,s2
    80000164:	60a6                	ld	ra,72(sp)
    80000166:	6406                	ld	s0,64(sp)
    80000168:	7942                	ld	s2,48(sp)
    8000016a:	6161                	addi	sp,sp,80
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00013517          	auipc	a0,0x13
    80000190:	3b450513          	addi	a0,a0,948 # 80013540 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aa4080e7          	jalr	-1372(ra) # 80000c38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00013497          	auipc	s1,0x13
    800001a0:	3a448493          	addi	s1,s1,932 # 80013540 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00013917          	auipc	s2,0x13
    800001a8:	43490913          	addi	s2,s2,1076 # 800135d8 <cons+0x98>
  while(n > 0){
    800001ac:	0d305763          	blez	s3,8000027a <consoleread+0x10c>
    while(cons.r == cons.w){
    800001b0:	0984a783          	lw	a5,152(s1)
    800001b4:	09c4a703          	lw	a4,156(s1)
    800001b8:	0af71c63          	bne	a4,a5,80000270 <consoleread+0x102>
      if(killed(myproc())){
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	8be080e7          	jalr	-1858(ra) # 80001a7a <myproc>
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	5d4080e7          	jalr	1492(ra) # 80002798 <killed>
    800001cc:	e52d                	bnez	a0,80000236 <consoleread+0xc8>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	312080e7          	jalr	786(ra) # 800024e4 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70de3          	beq	a4,a5,800001bc <consoleread+0x4e>
    800001e6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e8:	00013717          	auipc	a4,0x13
    800001ec:	35870713          	addi	a4,a4,856 # 80013540 <cons>
    800001f0:	0017869b          	addiw	a3,a5,1
    800001f4:	08d72c23          	sw	a3,152(a4)
    800001f8:	07f7f693          	andi	a3,a5,127
    800001fc:	9736                	add	a4,a4,a3
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000206:	4691                	li	a3,4
    80000208:	04db8a63          	beq	s7,a3,8000025c <consoleread+0xee>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000020c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	faf40613          	addi	a2,s0,-81
    80000216:	85d2                	mv	a1,s4
    80000218:	8556                	mv	a0,s5
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	6fe080e7          	jalr	1790(ra) # 80002918 <either_copyout>
    80000222:	57fd                	li	a5,-1
    80000224:	04f50a63          	beq	a0,a5,80000278 <consoleread+0x10a>
      break;

    dst++;
    80000228:	0a05                	addi	s4,s4,1
    --n;
    8000022a:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000022c:	47a9                	li	a5,10
    8000022e:	06fb8163          	beq	s7,a5,80000290 <consoleread+0x122>
    80000232:	6be2                	ld	s7,24(sp)
    80000234:	bfa5                	j	800001ac <consoleread+0x3e>
        release(&cons.lock);
    80000236:	00013517          	auipc	a0,0x13
    8000023a:	30a50513          	addi	a0,a0,778 # 80013540 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	aae080e7          	jalr	-1362(ra) # 80000cec <release>
        return -1;
    80000246:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000248:	60e6                	ld	ra,88(sp)
    8000024a:	6446                	ld	s0,80(sp)
    8000024c:	64a6                	ld	s1,72(sp)
    8000024e:	6906                	ld	s2,64(sp)
    80000250:	79e2                	ld	s3,56(sp)
    80000252:	7a42                	ld	s4,48(sp)
    80000254:	7aa2                	ld	s5,40(sp)
    80000256:	7b02                	ld	s6,32(sp)
    80000258:	6125                	addi	sp,sp,96
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	0009871b          	sext.w	a4,s3
    80000260:	01677a63          	bgeu	a4,s6,80000274 <consoleread+0x106>
        cons.r--;
    80000264:	00013717          	auipc	a4,0x13
    80000268:	36f72a23          	sw	a5,884(a4) # 800135d8 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00013517          	auipc	a0,0x13
    8000027e:	2c650513          	addi	a0,a0,710 # 80013540 <cons>
    80000282:	00001097          	auipc	ra,0x1
    80000286:	a6a080e7          	jalr	-1430(ra) # 80000cec <release>
  return target - n;
    8000028a:	413b053b          	subw	a0,s6,s3
    8000028e:	bf6d                	j	80000248 <consoleread+0xda>
    80000290:	6be2                	ld	s7,24(sp)
    80000292:	b7e5                	j	8000027a <consoleread+0x10c>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	59c080e7          	jalr	1436(ra) # 80000840 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	58a080e7          	jalr	1418(ra) # 80000840 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	574080e7          	jalr	1396(ra) # 80000840 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	1000                	addi	s0,sp,32
    800002e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e2:	00013517          	auipc	a0,0x13
    800002e6:	25e50513          	addi	a0,a0,606 # 80013540 <cons>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	94e080e7          	jalr	-1714(ra) # 80000c38 <acquire>

  switch(c){
    800002f2:	47d5                	li	a5,21
    800002f4:	0af48563          	beq	s1,a5,8000039e <consoleintr+0xc8>
    800002f8:	0297c963          	blt	a5,s1,8000032a <consoleintr+0x54>
    800002fc:	47a1                	li	a5,8
    800002fe:	0ef48c63          	beq	s1,a5,800003f6 <consoleintr+0x120>
    80000302:	47c1                	li	a5,16
    80000304:	10f49f63          	bne	s1,a5,80000422 <consoleintr+0x14c>
  case C('P'):  // Print process list.
    procdump();
    80000308:	00002097          	auipc	ra,0x2
    8000030c:	6c0080e7          	jalr	1728(ra) # 800029c8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000310:	00013517          	auipc	a0,0x13
    80000314:	23050513          	addi	a0,a0,560 # 80013540 <cons>
    80000318:	00001097          	auipc	ra,0x1
    8000031c:	9d4080e7          	jalr	-1580(ra) # 80000cec <release>
}
    80000320:	60e2                	ld	ra,24(sp)
    80000322:	6442                	ld	s0,16(sp)
    80000324:	64a2                	ld	s1,8(sp)
    80000326:	6105                	addi	sp,sp,32
    80000328:	8082                	ret
  switch(c){
    8000032a:	07f00793          	li	a5,127
    8000032e:	0cf48463          	beq	s1,a5,800003f6 <consoleintr+0x120>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000332:	00013717          	auipc	a4,0x13
    80000336:	20e70713          	addi	a4,a4,526 # 80013540 <cons>
    8000033a:	0a072783          	lw	a5,160(a4)
    8000033e:	09872703          	lw	a4,152(a4)
    80000342:	9f99                	subw	a5,a5,a4
    80000344:	07f00713          	li	a4,127
    80000348:	fcf764e3          	bltu	a4,a5,80000310 <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    8000034c:	47b5                	li	a5,13
    8000034e:	0cf48d63          	beq	s1,a5,80000428 <consoleintr+0x152>
      consputc(c);
    80000352:	8526                	mv	a0,s1
    80000354:	00000097          	auipc	ra,0x0
    80000358:	f40080e7          	jalr	-192(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000035c:	00013797          	auipc	a5,0x13
    80000360:	1e478793          	addi	a5,a5,484 # 80013540 <cons>
    80000364:	0a07a683          	lw	a3,160(a5)
    80000368:	0016871b          	addiw	a4,a3,1
    8000036c:	0007061b          	sext.w	a2,a4
    80000370:	0ae7a023          	sw	a4,160(a5)
    80000374:	07f6f693          	andi	a3,a3,127
    80000378:	97b6                	add	a5,a5,a3
    8000037a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000037e:	47a9                	li	a5,10
    80000380:	0cf48b63          	beq	s1,a5,80000456 <consoleintr+0x180>
    80000384:	4791                	li	a5,4
    80000386:	0cf48863          	beq	s1,a5,80000456 <consoleintr+0x180>
    8000038a:	00013797          	auipc	a5,0x13
    8000038e:	24e7a783          	lw	a5,590(a5) # 800135d8 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00013717          	auipc	a4,0x13
    800003a4:	1a070713          	addi	a4,a4,416 # 80013540 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00013497          	auipc	s1,0x13
    800003b4:	19048493          	addi	s1,s1,400 # 80013540 <cons>
    while(cons.e != cons.w &&
    800003b8:	4929                	li	s2,10
    800003ba:	02f70a63          	beq	a4,a5,800003ee <consoleintr+0x118>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003be:	37fd                	addiw	a5,a5,-1
    800003c0:	07f7f713          	andi	a4,a5,127
    800003c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c6:	01874703          	lbu	a4,24(a4)
    800003ca:	03270463          	beq	a4,s2,800003f2 <consoleintr+0x11c>
      cons.e--;
    800003ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d2:	10000513          	li	a0,256
    800003d6:	00000097          	auipc	ra,0x0
    800003da:	ebe080e7          	jalr	-322(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003de:	0a04a783          	lw	a5,160(s1)
    800003e2:	09c4a703          	lw	a4,156(s1)
    800003e6:	fcf71ce3          	bne	a4,a5,800003be <consoleintr+0xe8>
    800003ea:	6902                	ld	s2,0(sp)
    800003ec:	b715                	j	80000310 <consoleintr+0x3a>
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	b705                	j	80000310 <consoleintr+0x3a>
    800003f2:	6902                	ld	s2,0(sp)
    800003f4:	bf31                	j	80000310 <consoleintr+0x3a>
    if(cons.e != cons.w){
    800003f6:	00013717          	auipc	a4,0x13
    800003fa:	14a70713          	addi	a4,a4,330 # 80013540 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addiw	a5,a5,-1
    8000040c:	00013717          	auipc	a4,0x13
    80000410:	1cf72a23          	sw	a5,468(a4) # 800135e0 <cons+0xa0>
      consputc(BACKSPACE);
    80000414:	10000513          	li	a0,256
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	e7c080e7          	jalr	-388(ra) # 80000294 <consputc>
    80000420:	bdc5                	j	80000310 <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000422:	ee0487e3          	beqz	s1,80000310 <consoleintr+0x3a>
    80000426:	b731                	j	80000332 <consoleintr+0x5c>
      consputc(c);
    80000428:	4529                	li	a0,10
    8000042a:	00000097          	auipc	ra,0x0
    8000042e:	e6a080e7          	jalr	-406(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000432:	00013797          	auipc	a5,0x13
    80000436:	10e78793          	addi	a5,a5,270 # 80013540 <cons>
    8000043a:	0a07a703          	lw	a4,160(a5)
    8000043e:	0017069b          	addiw	a3,a4,1
    80000442:	0006861b          	sext.w	a2,a3
    80000446:	0ad7a023          	sw	a3,160(a5)
    8000044a:	07f77713          	andi	a4,a4,127
    8000044e:	97ba                	add	a5,a5,a4
    80000450:	4729                	li	a4,10
    80000452:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000456:	00013797          	auipc	a5,0x13
    8000045a:	18c7a323          	sw	a2,390(a5) # 800135dc <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00013517          	auipc	a0,0x13
    80000462:	17a50513          	addi	a0,a0,378 # 800135d8 <cons+0x98>
    80000466:	00002097          	auipc	ra,0x2
    8000046a:	0e2080e7          	jalr	226(ra) # 80002548 <wakeup>
    8000046e:	b54d                	j	80000310 <consoleintr+0x3a>

0000000080000470 <consoleinit>:

void
consoleinit(void)
{
    80000470:	1141                	addi	sp,sp,-16
    80000472:	e406                	sd	ra,8(sp)
    80000474:	e022                	sd	s0,0(sp)
    80000476:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000478:	00008597          	auipc	a1,0x8
    8000047c:	b8858593          	addi	a1,a1,-1144 # 80008000 <etext>
    80000480:	00013517          	auipc	a0,0x13
    80000484:	0c050513          	addi	a0,a0,192 # 80013540 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	720080e7          	jalr	1824(ra) # 80000ba8 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	0002b797          	auipc	a5,0x2b
    8000049c:	45078793          	addi	a5,a5,1104 # 8002b8e8 <devsw>
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	cce70713          	addi	a4,a4,-818 # 8000016e <consoleread>
    800004a8:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004aa:	00000717          	auipc	a4,0x0
    800004ae:	c5670713          	addi	a4,a4,-938 # 80000100 <consolewrite>
    800004b2:	ef98                	sd	a4,24(a5)
}
    800004b4:	60a2                	ld	ra,8(sp)
    800004b6:	6402                	ld	s0,0(sp)
    800004b8:	0141                	addi	sp,sp,16
    800004ba:	8082                	ret

00000000800004bc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004bc:	7179                	addi	sp,sp,-48
    800004be:	f406                	sd	ra,40(sp)
    800004c0:	f022                	sd	s0,32(sp)
    800004c2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c4:	c219                	beqz	a2,800004ca <printint+0xe>
    800004c6:	08054963          	bltz	a0,80000558 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ca:	2501                	sext.w	a0,a0
    800004cc:	4881                	li	a7,0
    800004ce:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004d2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d4:	2581                	sext.w	a1,a1
    800004d6:	00008617          	auipc	a2,0x8
    800004da:	25260613          	addi	a2,a2,594 # 80008728 <digits>
    800004de:	883a                	mv	a6,a4
    800004e0:	2705                	addiw	a4,a4,1
    800004e2:	02b577bb          	remuw	a5,a0,a1
    800004e6:	1782                	slli	a5,a5,0x20
    800004e8:	9381                	srli	a5,a5,0x20
    800004ea:	97b2                	add	a5,a5,a2
    800004ec:	0007c783          	lbu	a5,0(a5)
    800004f0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f4:	0005079b          	sext.w	a5,a0
    800004f8:	02b5553b          	divuw	a0,a0,a1
    800004fc:	0685                	addi	a3,a3,1
    800004fe:	feb7f0e3          	bgeu	a5,a1,800004de <printint+0x22>

  if(sign)
    80000502:	00088c63          	beqz	a7,8000051a <printint+0x5e>
    buf[i++] = '-';
    80000506:	fe070793          	addi	a5,a4,-32
    8000050a:	00878733          	add	a4,a5,s0
    8000050e:	02d00793          	li	a5,45
    80000512:	fef70823          	sb	a5,-16(a4)
    80000516:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000051a:	02e05b63          	blez	a4,80000550 <printint+0x94>
    8000051e:	ec26                	sd	s1,24(sp)
    80000520:	e84a                	sd	s2,16(sp)
    80000522:	fd040793          	addi	a5,s0,-48
    80000526:	00e784b3          	add	s1,a5,a4
    8000052a:	fff78913          	addi	s2,a5,-1
    8000052e:	993a                	add	s2,s2,a4
    80000530:	377d                	addiw	a4,a4,-1
    80000532:	1702                	slli	a4,a4,0x20
    80000534:	9301                	srli	a4,a4,0x20
    80000536:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d56080e7          	jalr	-682(ra) # 80000294 <consputc>
  while(--i >= 0)
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x7e>
    8000054c:	64e2                	ld	s1,24(sp)
    8000054e:	6942                	ld	s2,16(sp)
}
    80000550:	70a2                	ld	ra,40(sp)
    80000552:	7402                	ld	s0,32(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4885                	li	a7,1
    x = -xx;
    8000055e:	bf85                	j	800004ce <printint+0x12>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	addi	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	addi	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00013797          	auipc	a5,0x13
    80000570:	0807aa23          	sw	zero,148(a5) # 80013600 <pr+0x18>
  printf("panic: ");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	a9450513          	addi	a0,a0,-1388 # 80008008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00008517          	auipc	a0,0x8
    80000592:	a8250513          	addi	a0,a0,-1406 # 80008010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	0000b717          	auipc	a4,0xb
    800005a4:	e2f72023          	sw	a5,-480(a4) # 8000b3c0 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	addi	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00013d17          	auipc	s10,0x13
    800005ce:	036d2d03          	lw	s10,54(s10) # 80013600 <pr+0x18>
  if(locking)
    800005d2:	040d1463          	bnez	s10,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050b63          	beqz	a0,8000077c <printf+0x1d2>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	ec6e                	sd	s11,24(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	4cc1                	li	s9,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000608:	00008a97          	auipc	s5,0x8
    8000060c:	120a8a93          	addi	s5,s5,288 # 80008728 <digits>
    switch(c){
    80000610:	07300c13          	li	s8,115
    80000614:	06400d93          	li	s11,100
    80000618:	a0b1                	j	80000664 <printf+0xba>
    acquire(&pr.lock);
    8000061a:	00013517          	auipc	a0,0x13
    8000061e:	fce50513          	addi	a0,a0,-50 # 800135e8 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	616080e7          	jalr	1558(ra) # 80000c38 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	9e250513          	addi	a0,a0,-1566 # 80008020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c46080e7          	jalr	-954(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2985                	addiw	s3,s3,1
    80000658:	013a07b3          	add	a5,s4,s3
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050563          	beqz	a0,8000076a <printf+0x1c0>
    if(c != '%'){
    80000664:	ff6515e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    80000668:	2985                	addiw	s3,s3,1
    8000066a:	013a07b3          	add	a5,s4,s3
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000676:	10078b63          	beqz	a5,8000078c <printf+0x1e2>
    switch(c){
    8000067a:	05778a63          	beq	a5,s7,800006ce <printf+0x124>
    8000067e:	02fbf663          	bgeu	s7,a5,800006aa <printf+0x100>
    80000682:	09878863          	beq	a5,s8,80000712 <printf+0x168>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79563          	bne	a5,a4,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85e6                	mv	a1,s9
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e1c080e7          	jalr	-484(ra) # 800004bc <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	09678f63          	beq	a5,s6,80000748 <printf+0x19e>
    800006ae:	0bb79363          	bne	a5,s11,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	df8080e7          	jalr	-520(ra) # 800004bc <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	bb2080e7          	jalr	-1102(ra) # 80000294 <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	ba6080e7          	jalr	-1114(ra) # 80000294 <consputc>
    800006f6:	84e6                	mv	s1,s9
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c95793          	srli	a5,s2,0x3c
    800006fc:	97d6                	add	a5,a5,s5
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b92080e7          	jalr	-1134(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0912                	slli	s2,s2,0x4
    8000070c:	34fd                	addiw	s1,s1,-1
    8000070e:	f4ed                	bnez	s1,800006f8 <printf+0x14e>
    80000710:	b799                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000712:	f8843783          	ld	a5,-120(s0)
    80000716:	00878713          	addi	a4,a5,8
    8000071a:	f8e43423          	sd	a4,-120(s0)
    8000071e:	6384                	ld	s1,0(a5)
    80000720:	cc89                	beqz	s1,8000073a <printf+0x190>
      for(; *s; s++)
    80000722:	0004c503          	lbu	a0,0(s1)
    80000726:	d905                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b6c080e7          	jalr	-1172(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000730:	0485                	addi	s1,s1,1
    80000732:	0004c503          	lbu	a0,0(s1)
    80000736:	f96d                	bnez	a0,80000728 <printf+0x17e>
    80000738:	bf39                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073a:	00008497          	auipc	s1,0x8
    8000073e:	8de48493          	addi	s1,s1,-1826 # 80008018 <etext+0x18>
      for(; *s; s++)
    80000742:	02800513          	li	a0,40
    80000746:	b7cd                	j	80000728 <printf+0x17e>
      consputc('%');
    80000748:	855a                	mv	a0,s6
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b4a080e7          	jalr	-1206(ra) # 80000294 <consputc>
      break;
    80000752:	b711                	j	80000656 <printf+0xac>
      consputc('%');
    80000754:	855a                	mv	a0,s6
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b3e080e7          	jalr	-1218(ra) # 80000294 <consputc>
      consputc(c);
    8000075e:	8526                	mv	a0,s1
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b34080e7          	jalr	-1228(ra) # 80000294 <consputc>
      break;
    80000768:	b5fd                	j	80000656 <printf+0xac>
    8000076a:	74a6                	ld	s1,104(sp)
    8000076c:	7906                	ld	s2,96(sp)
    8000076e:	69e6                	ld	s3,88(sp)
    80000770:	6aa6                	ld	s5,72(sp)
    80000772:	6b06                	ld	s6,64(sp)
    80000774:	7be2                	ld	s7,56(sp)
    80000776:	7c42                	ld	s8,48(sp)
    80000778:	7ca2                	ld	s9,40(sp)
    8000077a:	6de2                	ld	s11,24(sp)
  if(locking)
    8000077c:	020d1263          	bnez	s10,800007a0 <printf+0x1f6>
}
    80000780:	70e6                	ld	ra,120(sp)
    80000782:	7446                	ld	s0,112(sp)
    80000784:	6a46                	ld	s4,80(sp)
    80000786:	7d02                	ld	s10,32(sp)
    80000788:	6129                	addi	sp,sp,192
    8000078a:	8082                	ret
    8000078c:	74a6                	ld	s1,104(sp)
    8000078e:	7906                	ld	s2,96(sp)
    80000790:	69e6                	ld	s3,88(sp)
    80000792:	6aa6                	ld	s5,72(sp)
    80000794:	6b06                	ld	s6,64(sp)
    80000796:	7be2                	ld	s7,56(sp)
    80000798:	7c42                	ld	s8,48(sp)
    8000079a:	7ca2                	ld	s9,40(sp)
    8000079c:	6de2                	ld	s11,24(sp)
    8000079e:	bff9                	j	8000077c <printf+0x1d2>
    release(&pr.lock);
    800007a0:	00013517          	auipc	a0,0x13
    800007a4:	e4850513          	addi	a0,a0,-440 # 800135e8 <pr>
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	544080e7          	jalr	1348(ra) # 80000cec <release>
}
    800007b0:	bfc1                	j	80000780 <printf+0x1d6>

00000000800007b2 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b2:	1101                	addi	sp,sp,-32
    800007b4:	ec06                	sd	ra,24(sp)
    800007b6:	e822                	sd	s0,16(sp)
    800007b8:	e426                	sd	s1,8(sp)
    800007ba:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007bc:	00013497          	auipc	s1,0x13
    800007c0:	e2c48493          	addi	s1,s1,-468 # 800135e8 <pr>
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	86c58593          	addi	a1,a1,-1940 # 80008030 <etext+0x30>
    800007cc:	8526                	mv	a0,s1
    800007ce:	00000097          	auipc	ra,0x0
    800007d2:	3da080e7          	jalr	986(ra) # 80000ba8 <initlock>
  pr.locking = 1;
    800007d6:	4785                	li	a5,1
    800007d8:	cc9c                	sw	a5,24(s1)
}
    800007da:	60e2                	ld	ra,24(sp)
    800007dc:	6442                	ld	s0,16(sp)
    800007de:	64a2                	ld	s1,8(sp)
    800007e0:	6105                	addi	sp,sp,32
    800007e2:	8082                	ret

00000000800007e4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e4:	1141                	addi	sp,sp,-16
    800007e6:	e406                	sd	ra,8(sp)
    800007e8:	e022                	sd	s0,0(sp)
    800007ea:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ec:	100007b7          	lui	a5,0x10000
    800007f0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f4:	10000737          	lui	a4,0x10000
    800007f8:	f8000693          	li	a3,-128
    800007fc:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000800:	468d                	li	a3,3
    80000802:	10000637          	lui	a2,0x10000
    80000806:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080e:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000812:	10000737          	lui	a4,0x10000
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00008597          	auipc	a1,0x8
    80000824:	81858593          	addi	a1,a1,-2024 # 80008038 <etext+0x38>
    80000828:	00013517          	auipc	a0,0x13
    8000082c:	de050513          	addi	a0,a0,-544 # 80013608 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	378080e7          	jalr	888(ra) # 80000ba8 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	addi	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	addi	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3a0080e7          	jalr	928(ra) # 80000bec <push_off>

  if(panicked){
    80000854:	0000b797          	auipc	a5,0xb
    80000858:	b6c7a783          	lw	a5,-1172(a5) # 8000b3c0 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	andi	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	412080e7          	jalr	1042(ra) # 80000c8c <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	addi	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	0000b797          	auipc	a5,0xb
    80000892:	b3a7b783          	ld	a5,-1222(a5) # 8000b3c8 <uart_tx_r>
    80000896:	0000b717          	auipc	a4,0xb
    8000089a:	b3a73703          	ld	a4,-1222(a4) # 8000b3d0 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	addi	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	addi	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00013a97          	auipc	s5,0x13
    800008c0:	d4ca8a93          	addi	s5,s5,-692 # 80013608 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	0000b497          	auipc	s1,0xb
    800008c8:	b0448493          	addi	s1,s1,-1276 # 8000b3c8 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	0000b997          	auipc	s3,0xb
    800008d4:	b0098993          	addi	s3,s3,-1280 # 8000b3d0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	andi	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	addi	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	c56080e7          	jalr	-938(ra) # 80002548 <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3)
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	addi	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	addi	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	addi	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00013517          	auipc	a0,0x13
    80000934:	cd850513          	addi	a0,a0,-808 # 80013608 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	300080e7          	jalr	768(ra) # 80000c38 <acquire>
  if(panicked){
    80000940:	0000b797          	auipc	a5,0xb
    80000944:	a807a783          	lw	a5,-1408(a5) # 8000b3c0 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	0000b717          	auipc	a4,0xb
    8000094e:	a8673703          	ld	a4,-1402(a4) # 8000b3d0 <uart_tx_w>
    80000952:	0000b797          	auipc	a5,0xb
    80000956:	a767b783          	ld	a5,-1418(a5) # 8000b3c8 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00013997          	auipc	s3,0x13
    80000962:	caa98993          	addi	s3,s3,-854 # 80013608 <uart_tx_lock>
    80000966:	0000b497          	auipc	s1,0xb
    8000096a:	a6248493          	addi	s1,s1,-1438 # 8000b3c8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	0000b917          	auipc	s2,0xb
    80000972:	a6290913          	addi	s2,s2,-1438 # 8000b3d0 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	b66080e7          	jalr	-1178(ra) # 800024e4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	addi	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00013497          	auipc	s1,0x13
    80000998:	c7448493          	addi	s1,s1,-908 # 80013608 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	0000b797          	auipc	a5,0xb
    800009ac:	a2e7b423          	sd	a4,-1496(a5) # 8000b3d0 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	332080e7          	jalr	818(ra) # 80000cec <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	addi	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	addi	sp,sp,-16
    800009d6:	e422                	sd	s0,8(sp)
    800009d8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009da:	100007b7          	lui	a5,0x10000
    800009de:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009e0:	0007c783          	lbu	a5,0(a5)
    800009e4:	8b85                	andi	a5,a5,1
    800009e6:	cb81                	beqz	a5,800009f6 <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	addi	sp,sp,16
    800009f4:	8082                	ret
    return -1;
    800009f6:	557d                	li	a0,-1
    800009f8:	bfe5                	j	800009f0 <uartgetc+0x1c>

00000000800009fa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a04:	54fd                	li	s1,-1
    80000a06:	a029                	j	80000a10 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	8ce080e7          	jalr	-1842(ra) # 800002d6 <consoleintr>
    int c = uartgetc();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	fc4080e7          	jalr	-60(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a18:	fe9518e3          	bne	a0,s1,80000a08 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1c:	00013497          	auipc	s1,0x13
    80000a20:	bec48493          	addi	s1,s1,-1044 # 80013608 <uart_tx_lock>
    80000a24:	8526                	mv	a0,s1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	212080e7          	jalr	530(ra) # 80000c38 <acquire>
  uartstart();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	e60080e7          	jalr	-416(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a36:	8526                	mv	a0,s1
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2b4080e7          	jalr	692(ra) # 80000cec <release>
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret

0000000080000a4a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4a:	1101                	addi	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	e04a                	sd	s2,0(sp)
    80000a54:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a56:	03451793          	slli	a5,a0,0x34
    80000a5a:	ebb9                	bnez	a5,80000ab0 <kfree+0x66>
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	0002c797          	auipc	a5,0x2c
    80000a62:	02278793          	addi	a5,a5,34 # 8002ca80 <end>
    80000a66:	04f56563          	bltu	a0,a5,80000ab0 <kfree+0x66>
    80000a6a:	47c5                	li	a5,17
    80000a6c:	07ee                	slli	a5,a5,0x1b
    80000a6e:	04f57163          	bgeu	a0,a5,80000ab0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2be080e7          	jalr	702(ra) # 80000d34 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	00013917          	auipc	s2,0x13
    80000a82:	bc290913          	addi	s2,s2,-1086 # 80013640 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1b0080e7          	jalr	432(ra) # 80000c38 <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	250080e7          	jalr	592(ra) # 80000cec <release>
}
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6902                	ld	s2,0(sp)
    80000aac:	6105                	addi	sp,sp,32
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	59050513          	addi	a0,a0,1424 # 80008040 <etext+0x40>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	addi	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aca:	6785                	lui	a5,0x1
    80000acc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad0:	00e504b3          	add	s1,a0,a4
    80000ad4:	777d                	lui	a4,0xfffff
    80000ad6:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0295e463          	bltu	a1,s1,80000b02 <freerange+0x42>
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f5c080e7          	jalr	-164(ra) # 80000a4a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{
    80000b0c:	1141                	addi	sp,sp,-16
    80000b0e:	e406                	sd	ra,8(sp)
    80000b10:	e022                	sd	s0,0(sp)
    80000b12:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b14:	00007597          	auipc	a1,0x7
    80000b18:	53458593          	addi	a1,a1,1332 # 80008048 <etext+0x48>
    80000b1c:	00013517          	auipc	a0,0x13
    80000b20:	b2450513          	addi	a0,a0,-1244 # 80013640 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	084080e7          	jalr	132(ra) # 80000ba8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	slli	a1,a1,0x1b
    80000b30:	0002c517          	auipc	a0,0x2c
    80000b34:	f5050513          	addi	a0,a0,-176 # 8002ca80 <end>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f88080e7          	jalr	-120(ra) # 80000ac0 <freerange>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b48:	1101                	addi	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b52:	00013497          	auipc	s1,0x13
    80000b56:	aee48493          	addi	s1,s1,-1298 # 80013640 <kmem>
    80000b5a:	8526                	mv	a0,s1
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0dc080e7          	jalr	220(ra) # 80000c38 <acquire>
  r = kmem.freelist;
    80000b64:	6c84                	ld	s1,24(s1)
  if(r)
    80000b66:	c885                	beqz	s1,80000b96 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b68:	609c                	ld	a5,0(s1)
    80000b6a:	00013517          	auipc	a0,0x13
    80000b6e:	ad650513          	addi	a0,a0,-1322 # 80013640 <kmem>
    80000b72:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	178080e7          	jalr	376(ra) # 80000cec <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7c:	6605                	lui	a2,0x1
    80000b7e:	4595                	li	a1,5
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	1b2080e7          	jalr	434(ra) # 80000d34 <memset>
  return (void*)r;
}
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	60e2                	ld	ra,24(sp)
    80000b8e:	6442                	ld	s0,16(sp)
    80000b90:	64a2                	ld	s1,8(sp)
    80000b92:	6105                	addi	sp,sp,32
    80000b94:	8082                	ret
  release(&kmem.lock);
    80000b96:	00013517          	auipc	a0,0x13
    80000b9a:	aaa50513          	addi	a0,a0,-1366 # 80013640 <kmem>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	14e080e7          	jalr	334(ra) # 80000cec <release>
  if(r)
    80000ba6:	b7d5                	j	80000b8a <kalloc+0x42>

0000000080000ba8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e422                	sd	s0,8(sp)
    80000bac:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bae:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb4:	00053823          	sd	zero,16(a0)
}
    80000bb8:	6422                	ld	s0,8(sp)
    80000bba:	0141                	addi	sp,sp,16
    80000bbc:	8082                	ret

0000000080000bbe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bbe:	411c                	lw	a5,0(a0)
    80000bc0:	e399                	bnez	a5,80000bc6 <holding+0x8>
    80000bc2:	4501                	li	a0,0
  return r;
}
    80000bc4:	8082                	ret
{
    80000bc6:	1101                	addi	sp,sp,-32
    80000bc8:	ec06                	sd	ra,24(sp)
    80000bca:	e822                	sd	s0,16(sp)
    80000bcc:	e426                	sd	s1,8(sp)
    80000bce:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd0:	6904                	ld	s1,16(a0)
    80000bd2:	00001097          	auipc	ra,0x1
    80000bd6:	e8c080e7          	jalr	-372(ra) # 80001a5e <mycpu>
    80000bda:	40a48533          	sub	a0,s1,a0
    80000bde:	00153513          	seqz	a0,a0
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret

0000000080000bec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bec:	1101                	addi	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf6:	100024f3          	csrr	s1,sstatus
    80000bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c04:	00001097          	auipc	ra,0x1
    80000c08:	e5a080e7          	jalr	-422(ra) # 80001a5e <mycpu>
    80000c0c:	5d3c                	lw	a5,120(a0)
    80000c0e:	cf89                	beqz	a5,80000c28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	e4e080e7          	jalr	-434(ra) # 80001a5e <mycpu>
    80000c18:	5d3c                	lw	a5,120(a0)
    80000c1a:	2785                	addiw	a5,a5,1
    80000c1c:	dd3c                	sw	a5,120(a0)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    mycpu()->intena = old;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	e36080e7          	jalr	-458(ra) # 80001a5e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c30:	8085                	srli	s1,s1,0x1
    80000c32:	8885                	andi	s1,s1,1
    80000c34:	dd64                	sw	s1,124(a0)
    80000c36:	bfe9                	j	80000c10 <push_off+0x24>

0000000080000c38 <acquire>:
{
    80000c38:	1101                	addi	sp,sp,-32
    80000c3a:	ec06                	sd	ra,24(sp)
    80000c3c:	e822                	sd	s0,16(sp)
    80000c3e:	e426                	sd	s1,8(sp)
    80000c40:	1000                	addi	s0,sp,32
    80000c42:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	fa8080e7          	jalr	-88(ra) # 80000bec <push_off>
  if(holding(lk))
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	f70080e7          	jalr	-144(ra) # 80000bbe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	4705                	li	a4,1
  if(holding(lk))
    80000c58:	e115                	bnez	a0,80000c7c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5a:	87ba                	mv	a5,a4
    80000c5c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c60:	2781                	sext.w	a5,a5
    80000c62:	ffe5                	bnez	a5,80000c5a <acquire+0x22>
  __sync_synchronize();
    80000c64:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	df6080e7          	jalr	-522(ra) # 80001a5e <mycpu>
    80000c70:	e888                	sd	a0,16(s1)
}
    80000c72:	60e2                	ld	ra,24(sp)
    80000c74:	6442                	ld	s0,16(sp)
    80000c76:	64a2                	ld	s1,8(sp)
    80000c78:	6105                	addi	sp,sp,32
    80000c7a:	8082                	ret
    panic("acquire");
    80000c7c:	00007517          	auipc	a0,0x7
    80000c80:	3d450513          	addi	a0,a0,980 # 80008050 <etext+0x50>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	8dc080e7          	jalr	-1828(ra) # 80000560 <panic>

0000000080000c8c <pop_off>:

void
pop_off(void)
{
    80000c8c:	1141                	addi	sp,sp,-16
    80000c8e:	e406                	sd	ra,8(sp)
    80000c90:	e022                	sd	s0,0(sp)
    80000c92:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c94:	00001097          	auipc	ra,0x1
    80000c98:	dca080e7          	jalr	-566(ra) # 80001a5e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ca2:	e78d                	bnez	a5,80000ccc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca4:	5d3c                	lw	a5,120(a0)
    80000ca6:	02f05b63          	blez	a5,80000cdc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000caa:	37fd                	addiw	a5,a5,-1
    80000cac:	0007871b          	sext.w	a4,a5
    80000cb0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb2:	eb09                	bnez	a4,80000cc4 <pop_off+0x38>
    80000cb4:	5d7c                	lw	a5,124(a0)
    80000cb6:	c799                	beqz	a5,80000cc4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc4:	60a2                	ld	ra,8(sp)
    80000cc6:	6402                	ld	s0,0(sp)
    80000cc8:	0141                	addi	sp,sp,16
    80000cca:	8082                	ret
    panic("pop_off - interruptible");
    80000ccc:	00007517          	auipc	a0,0x7
    80000cd0:	38c50513          	addi	a0,a0,908 # 80008058 <etext+0x58>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	88c080e7          	jalr	-1908(ra) # 80000560 <panic>
    panic("pop_off");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39450513          	addi	a0,a0,916 # 80008070 <etext+0x70>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	87c080e7          	jalr	-1924(ra) # 80000560 <panic>

0000000080000cec <release>:
{
    80000cec:	1101                	addi	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	addi	s0,sp,32
    80000cf6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	ec6080e7          	jalr	-314(ra) # 80000bbe <holding>
    80000d00:	c115                	beqz	a0,80000d24 <release+0x38>
  lk->cpu = 0;
    80000d02:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d06:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000d0a:	0310000f          	fence	rw,w
    80000d0e:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	f7a080e7          	jalr	-134(ra) # 80000c8c <pop_off>
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	addi	sp,sp,32
    80000d22:	8082                	ret
    panic("release");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	35450513          	addi	a0,a0,852 # 80008078 <etext+0x78>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	834080e7          	jalr	-1996(ra) # 80000560 <panic>

0000000080000d34 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d34:	1141                	addi	sp,sp,-16
    80000d36:	e422                	sd	s0,8(sp)
    80000d38:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d3a:	ca19                	beqz	a2,80000d50 <memset+0x1c>
    80000d3c:	87aa                	mv	a5,a0
    80000d3e:	1602                	slli	a2,a2,0x20
    80000d40:	9201                	srli	a2,a2,0x20
    80000d42:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	addi	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x12>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d62:	1682                	slli	a3,a3,0x20
    80000d64:	9281                	srli	a3,a3,0x20
    80000d66:	0685                	addi	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	addi	a0,a0,1
    80000d78:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d96:	c205                	beqz	a2,80000db6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d98:	02a5e263          	bltu	a1,a0,80000dbc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d9c:	1602                	slli	a2,a2,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	00c587b3          	add	a5,a1,a2
{
    80000da4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000da6:	0585                	addi	a1,a1,1
    80000da8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd2581>
    80000daa:	fff5c683          	lbu	a3,-1(a1)
    80000dae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000db2:	feb79ae3          	bne	a5,a1,80000da6 <memmove+0x16>

  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	addi	sp,sp,16
    80000dba:	8082                	ret
  if(s < d && s + n > d){
    80000dbc:	02061693          	slli	a3,a2,0x20
    80000dc0:	9281                	srli	a3,a3,0x20
    80000dc2:	00d58733          	add	a4,a1,a3
    80000dc6:	fce57be3          	bgeu	a0,a4,80000d9c <memmove+0xc>
    d += n;
    80000dca:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dcc:	fff6079b          	addiw	a5,a2,-1
    80000dd0:	1782                	slli	a5,a5,0x20
    80000dd2:	9381                	srli	a5,a5,0x20
    80000dd4:	fff7c793          	not	a5,a5
    80000dd8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dda:	177d                	addi	a4,a4,-1
    80000ddc:	16fd                	addi	a3,a3,-1
    80000dde:	00074603          	lbu	a2,0(a4)
    80000de2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de6:	fef71ae3          	bne	a4,a5,80000dda <memmove+0x4a>
    80000dea:	b7f1                	j	80000db6 <memmove+0x26>

0000000080000dec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e406                	sd	ra,8(sp)
    80000df0:	e022                	sd	s0,0(sp)
    80000df2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df4:	00000097          	auipc	ra,0x0
    80000df8:	f9c080e7          	jalr	-100(ra) # 80000d90 <memmove>
}
    80000dfc:	60a2                	ld	ra,8(sp)
    80000dfe:	6402                	ld	s0,0(sp)
    80000e00:	0141                	addi	sp,sp,16
    80000e02:	8082                	ret

0000000080000e04 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e04:	1141                	addi	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0a:	ce11                	beqz	a2,80000e26 <strncmp+0x22>
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	cf89                	beqz	a5,80000e2a <strncmp+0x26>
    80000e12:	0005c703          	lbu	a4,0(a1)
    80000e16:	00f71a63          	bne	a4,a5,80000e2a <strncmp+0x26>
    n--, p++, q++;
    80000e1a:	367d                	addiw	a2,a2,-1
    80000e1c:	0505                	addi	a0,a0,1
    80000e1e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e20:	f675                	bnez	a2,80000e0c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e22:	4501                	li	a0,0
    80000e24:	a801                	j	80000e34 <strncmp+0x30>
    80000e26:	4501                	li	a0,0
    80000e28:	a031                	j	80000e34 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000e2a:	00054503          	lbu	a0,0(a0)
    80000e2e:	0005c783          	lbu	a5,0(a1)
    80000e32:	9d1d                	subw	a0,a0,a5
}
    80000e34:	6422                	ld	s0,8(sp)
    80000e36:	0141                	addi	sp,sp,16
    80000e38:	8082                	ret

0000000080000e3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e40:	87aa                	mv	a5,a0
    80000e42:	86b2                	mv	a3,a2
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	02d05563          	blez	a3,80000e70 <strncpy+0x36>
    80000e4a:	0785                	addi	a5,a5,1
    80000e4c:	0005c703          	lbu	a4,0(a1)
    80000e50:	fee78fa3          	sb	a4,-1(a5)
    80000e54:	0585                	addi	a1,a1,1
    80000e56:	f775                	bnez	a4,80000e42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e58:	873e                	mv	a4,a5
    80000e5a:	9fb5                	addw	a5,a5,a3
    80000e5c:	37fd                	addiw	a5,a5,-1
    80000e5e:	00c05963          	blez	a2,80000e70 <strncpy+0x36>
    *s++ = 0;
    80000e62:	0705                	addi	a4,a4,1
    80000e64:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e68:	40e786bb          	subw	a3,a5,a4
    80000e6c:	fed04be3          	bgtz	a3,80000e62 <strncpy+0x28>
  return os;
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	addi	sp,sp,16
    80000e74:	8082                	ret

0000000080000e76 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e7c:	02c05363          	blez	a2,80000ea2 <safestrcpy+0x2c>
    80000e80:	fff6069b          	addiw	a3,a2,-1
    80000e84:	1682                	slli	a3,a3,0x20
    80000e86:	9281                	srli	a3,a3,0x20
    80000e88:	96ae                	add	a3,a3,a1
    80000e8a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e8c:	00d58963          	beq	a1,a3,80000e9e <safestrcpy+0x28>
    80000e90:	0585                	addi	a1,a1,1
    80000e92:	0785                	addi	a5,a5,1
    80000e94:	fff5c703          	lbu	a4,-1(a1)
    80000e98:	fee78fa3          	sb	a4,-1(a5)
    80000e9c:	fb65                	bnez	a4,80000e8c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e9e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <strlen>:

int
strlen(const char *s)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eae:	00054783          	lbu	a5,0(a0)
    80000eb2:	cf91                	beqz	a5,80000ece <strlen+0x26>
    80000eb4:	0505                	addi	a0,a0,1
    80000eb6:	87aa                	mv	a5,a0
    80000eb8:	86be                	mv	a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	ff65                	bnez	a4,80000eb8 <strlen+0x10>
    80000ec2:	40a6853b          	subw	a0,a3,a0
    80000ec6:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <strlen+0x20>

0000000080000ed2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e406                	sd	ra,8(sp)
    80000ed6:	e022                	sd	s0,0(sp)
    80000ed8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	b74080e7          	jalr	-1164(ra) # 80001a4e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ee2:	0000a717          	auipc	a4,0xa
    80000ee6:	4f670713          	addi	a4,a4,1270 # 8000b3d8 <started>
  if(cpuid() == 0){
    80000eea:	c139                	beqz	a0,80000f30 <main+0x5e>
    while(started == 0)
    80000eec:	431c                	lw	a5,0(a4)
    80000eee:	2781                	sext.w	a5,a5
    80000ef0:	dff5                	beqz	a5,80000eec <main+0x1a>
      ;
    __sync_synchronize();
    80000ef2:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	b58080e7          	jalr	-1192(ra) # 80001a4e <cpuid>
    80000efe:	85aa                	mv	a1,a0
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	19850513          	addi	a0,a0,408 # 80008098 <etext+0x98>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	6a2080e7          	jalr	1698(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	0d8080e7          	jalr	216(ra) # 80000fe8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f18:	00002097          	auipc	ra,0x2
    80000f1c:	d9c080e7          	jalr	-612(ra) # 80002cb4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f20:	00005097          	auipc	ra,0x5
    80000f24:	654080e7          	jalr	1620(ra) # 80006574 <plicinithart>
  }

  scheduler();        
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	49a080e7          	jalr	1178(ra) # 800023c2 <scheduler>
    consoleinit();
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	540080e7          	jalr	1344(ra) # 80000470 <consoleinit>
    printfinit();
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	87a080e7          	jalr	-1926(ra) # 800007b2 <printfinit>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	0d050513          	addi	a0,a0,208 # 80008010 <etext+0x10>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	662080e7          	jalr	1634(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	13050513          	addi	a0,a0,304 # 80008080 <etext+0x80>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	652080e7          	jalr	1618(ra) # 800005aa <printf>
    printf("\n");
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	0b050513          	addi	a0,a0,176 # 80008010 <etext+0x10>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	642080e7          	jalr	1602(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	b9c080e7          	jalr	-1124(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	326080e7          	jalr	806(ra) # 8000129e <kvminit>
    kvminithart();   // turn on paging
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	068080e7          	jalr	104(ra) # 80000fe8 <kvminithart>
    procinit();      // process table
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	a02080e7          	jalr	-1534(ra) # 8000198a <procinit>
    trapinit();      // trap vectors
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	cfc080e7          	jalr	-772(ra) # 80002c8c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	d1c080e7          	jalr	-740(ra) # 80002cb4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	5ba080e7          	jalr	1466(ra) # 8000655a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	5cc080e7          	jalr	1484(ra) # 80006574 <plicinithart>
    binit();         // buffer cache
    80000fb0:	00002097          	auipc	ra,0x2
    80000fb4:	680080e7          	jalr	1664(ra) # 80003630 <binit>
    iinit();         // inode table
    80000fb8:	00003097          	auipc	ra,0x3
    80000fbc:	d36080e7          	jalr	-714(ra) # 80003cee <iinit>
    fileinit();      // file table
    80000fc0:	00004097          	auipc	ra,0x4
    80000fc4:	ce6080e7          	jalr	-794(ra) # 80004ca6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc8:	00005097          	auipc	ra,0x5
    80000fcc:	6b4080e7          	jalr	1716(ra) # 8000667c <virtio_disk_init>
    userinit();      // first user process
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	dde080e7          	jalr	-546(ra) # 80001dae <userinit>
    __sync_synchronize();
    80000fd8:	0330000f          	fence	rw,rw
    started = 1;
    80000fdc:	4785                	li	a5,1
    80000fde:	0000a717          	auipc	a4,0xa
    80000fe2:	3ef72d23          	sw	a5,1018(a4) # 8000b3d8 <started>
    80000fe6:	b789                	j	80000f28 <main+0x56>

0000000080000fe8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe8:	1141                	addi	sp,sp,-16
    80000fea:	e422                	sd	s0,8(sp)
    80000fec:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ff2:	0000a797          	auipc	a5,0xa
    80000ff6:	3ee7b783          	ld	a5,1006(a5) # 8000b3e0 <kernel_pagetable>
    80000ffa:	83b1                	srli	a5,a5,0xc
    80000ffc:	577d                	li	a4,-1
    80000ffe:	177e                	slli	a4,a4,0x3f
    80001000:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001002:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001006:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000100a:	6422                	ld	s0,8(sp)
    8000100c:	0141                	addi	sp,sp,16
    8000100e:	8082                	ret

0000000080001010 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001010:	7139                	addi	sp,sp,-64
    80001012:	fc06                	sd	ra,56(sp)
    80001014:	f822                	sd	s0,48(sp)
    80001016:	f426                	sd	s1,40(sp)
    80001018:	f04a                	sd	s2,32(sp)
    8000101a:	ec4e                	sd	s3,24(sp)
    8000101c:	e852                	sd	s4,16(sp)
    8000101e:	e456                	sd	s5,8(sp)
    80001020:	e05a                	sd	s6,0(sp)
    80001022:	0080                	addi	s0,sp,64
    80001024:	84aa                	mv	s1,a0
    80001026:	89ae                	mv	s3,a1
    80001028:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000102a:	57fd                	li	a5,-1
    8000102c:	83e9                	srli	a5,a5,0x1a
    8000102e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001030:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001032:	04b7f263          	bgeu	a5,a1,80001076 <walk+0x66>
    panic("walk");
    80001036:	00007517          	auipc	a0,0x7
    8000103a:	07a50513          	addi	a0,a0,122 # 800080b0 <etext+0xb0>
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	522080e7          	jalr	1314(ra) # 80000560 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001046:	060a8663          	beqz	s5,800010b2 <walk+0xa2>
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	afe080e7          	jalr	-1282(ra) # 80000b48 <kalloc>
    80001052:	84aa                	mv	s1,a0
    80001054:	c529                	beqz	a0,8000109e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001056:	6605                	lui	a2,0x1
    80001058:	4581                	li	a1,0
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	cda080e7          	jalr	-806(ra) # 80000d34 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001062:	00c4d793          	srli	a5,s1,0xc
    80001066:	07aa                	slli	a5,a5,0xa
    80001068:	0017e793          	ori	a5,a5,1
    8000106c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001070:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd2577>
    80001072:	036a0063          	beq	s4,s6,80001092 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001076:	0149d933          	srl	s2,s3,s4
    8000107a:	1ff97913          	andi	s2,s2,511
    8000107e:	090e                	slli	s2,s2,0x3
    80001080:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001082:	00093483          	ld	s1,0(s2)
    80001086:	0014f793          	andi	a5,s1,1
    8000108a:	dfd5                	beqz	a5,80001046 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000108c:	80a9                	srli	s1,s1,0xa
    8000108e:	04b2                	slli	s1,s1,0xc
    80001090:	b7c5                	j	80001070 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001092:	00c9d513          	srli	a0,s3,0xc
    80001096:	1ff57513          	andi	a0,a0,511
    8000109a:	050e                	slli	a0,a0,0x3
    8000109c:	9526                	add	a0,a0,s1
}
    8000109e:	70e2                	ld	ra,56(sp)
    800010a0:	7442                	ld	s0,48(sp)
    800010a2:	74a2                	ld	s1,40(sp)
    800010a4:	7902                	ld	s2,32(sp)
    800010a6:	69e2                	ld	s3,24(sp)
    800010a8:	6a42                	ld	s4,16(sp)
    800010aa:	6aa2                	ld	s5,8(sp)
    800010ac:	6b02                	ld	s6,0(sp)
    800010ae:	6121                	addi	sp,sp,64
    800010b0:	8082                	ret
        return 0;
    800010b2:	4501                	li	a0,0
    800010b4:	b7ed                	j	8000109e <walk+0x8e>

00000000800010b6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010b6:	57fd                	li	a5,-1
    800010b8:	83e9                	srli	a5,a5,0x1a
    800010ba:	00b7f463          	bgeu	a5,a1,800010c2 <walkaddr+0xc>
    return 0;
    800010be:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c0:	8082                	ret
{
    800010c2:	1141                	addi	sp,sp,-16
    800010c4:	e406                	sd	ra,8(sp)
    800010c6:	e022                	sd	s0,0(sp)
    800010c8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00000097          	auipc	ra,0x0
    800010d0:	f44080e7          	jalr	-188(ra) # 80001010 <walk>
  if(pte == 0)
    800010d4:	c105                	beqz	a0,800010f4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010d6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010d8:	0117f693          	andi	a3,a5,17
    800010dc:	4745                	li	a4,17
    return 0;
    800010de:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e0:	00e68663          	beq	a3,a4,800010ec <walkaddr+0x36>
}
    800010e4:	60a2                	ld	ra,8(sp)
    800010e6:	6402                	ld	s0,0(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret
  pa = PTE2PA(*pte);
    800010ec:	83a9                	srli	a5,a5,0xa
    800010ee:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010f2:	bfcd                	j	800010e4 <walkaddr+0x2e>
    return 0;
    800010f4:	4501                	li	a0,0
    800010f6:	b7fd                	j	800010e4 <walkaddr+0x2e>

00000000800010f8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010f8:	715d                	addi	sp,sp,-80
    800010fa:	e486                	sd	ra,72(sp)
    800010fc:	e0a2                	sd	s0,64(sp)
    800010fe:	fc26                	sd	s1,56(sp)
    80001100:	f84a                	sd	s2,48(sp)
    80001102:	f44e                	sd	s3,40(sp)
    80001104:	f052                	sd	s4,32(sp)
    80001106:	ec56                	sd	s5,24(sp)
    80001108:	e85a                	sd	s6,16(sp)
    8000110a:	e45e                	sd	s7,8(sp)
    8000110c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000110e:	c639                	beqz	a2,8000115c <mappages+0x64>
    80001110:	8aaa                	mv	s5,a0
    80001112:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001114:	777d                	lui	a4,0xfffff
    80001116:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000111a:	fff58993          	addi	s3,a1,-1
    8000111e:	99b2                	add	s3,s3,a2
    80001120:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001124:	893e                	mv	s2,a5
    80001126:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112a:	6b85                	lui	s7,0x1
    8000112c:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eda080e7          	jalr	-294(ra) # 80001010 <walk>
    8000113e:	cd1d                	beqz	a0,8000117c <mappages+0x84>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	e785                	bnez	a5,8000116c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	05390063          	beq	s2,s3,80001194 <mappages+0x9c>
    a += PGSIZE;
    80001158:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115a:	bfc9                	j	8000112c <mappages+0x34>
    panic("mappages: size");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f5c50513          	addi	a0,a0,-164 # 800080b8 <etext+0xb8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3fc080e7          	jalr	1020(ra) # 80000560 <panic>
      panic("mappages: remap");
    8000116c:	00007517          	auipc	a0,0x7
    80001170:	f5c50513          	addi	a0,a0,-164 # 800080c8 <etext+0xc8>
    80001174:	fffff097          	auipc	ra,0xfffff
    80001178:	3ec080e7          	jalr	1004(ra) # 80000560 <panic>
      return -1;
    8000117c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000117e:	60a6                	ld	ra,72(sp)
    80001180:	6406                	ld	s0,64(sp)
    80001182:	74e2                	ld	s1,56(sp)
    80001184:	7942                	ld	s2,48(sp)
    80001186:	79a2                	ld	s3,40(sp)
    80001188:	7a02                	ld	s4,32(sp)
    8000118a:	6ae2                	ld	s5,24(sp)
    8000118c:	6b42                	ld	s6,16(sp)
    8000118e:	6ba2                	ld	s7,8(sp)
    80001190:	6161                	addi	sp,sp,80
    80001192:	8082                	ret
  return 0;
    80001194:	4501                	li	a0,0
    80001196:	b7e5                	j	8000117e <mappages+0x86>

0000000080001198 <kvmmap>:
{
    80001198:	1141                	addi	sp,sp,-16
    8000119a:	e406                	sd	ra,8(sp)
    8000119c:	e022                	sd	s0,0(sp)
    8000119e:	0800                	addi	s0,sp,16
    800011a0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011a2:	86b2                	mv	a3,a2
    800011a4:	863e                	mv	a2,a5
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	f52080e7          	jalr	-174(ra) # 800010f8 <mappages>
    800011ae:	e509                	bnez	a0,800011b8 <kvmmap+0x20>
}
    800011b0:	60a2                	ld	ra,8(sp)
    800011b2:	6402                	ld	s0,0(sp)
    800011b4:	0141                	addi	sp,sp,16
    800011b6:	8082                	ret
    panic("kvmmap");
    800011b8:	00007517          	auipc	a0,0x7
    800011bc:	f2050513          	addi	a0,a0,-224 # 800080d8 <etext+0xd8>
    800011c0:	fffff097          	auipc	ra,0xfffff
    800011c4:	3a0080e7          	jalr	928(ra) # 80000560 <panic>

00000000800011c8 <kvmmake>:
{
    800011c8:	1101                	addi	sp,sp,-32
    800011ca:	ec06                	sd	ra,24(sp)
    800011cc:	e822                	sd	s0,16(sp)
    800011ce:	e426                	sd	s1,8(sp)
    800011d0:	e04a                	sd	s2,0(sp)
    800011d2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	974080e7          	jalr	-1676(ra) # 80000b48 <kalloc>
    800011dc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011de:	6605                	lui	a2,0x1
    800011e0:	4581                	li	a1,0
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	b52080e7          	jalr	-1198(ra) # 80000d34 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ea:	4719                	li	a4,6
    800011ec:	6685                	lui	a3,0x1
    800011ee:	10000637          	lui	a2,0x10000
    800011f2:	100005b7          	lui	a1,0x10000
    800011f6:	8526                	mv	a0,s1
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	fa0080e7          	jalr	-96(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001200:	4719                	li	a4,6
    80001202:	6685                	lui	a3,0x1
    80001204:	10001637          	lui	a2,0x10001
    80001208:	100015b7          	lui	a1,0x10001
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f8a080e7          	jalr	-118(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	004006b7          	lui	a3,0x400
    8000121c:	0c000637          	lui	a2,0xc000
    80001220:	0c0005b7          	lui	a1,0xc000
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f72080e7          	jalr	-142(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000122e:	00007917          	auipc	s2,0x7
    80001232:	dd290913          	addi	s2,s2,-558 # 80008000 <etext>
    80001236:	4729                	li	a4,10
    80001238:	80007697          	auipc	a3,0x80007
    8000123c:	dc868693          	addi	a3,a3,-568 # 8000 <_entry-0x7fff8000>
    80001240:	4605                	li	a2,1
    80001242:	067e                	slli	a2,a2,0x1f
    80001244:	85b2                	mv	a1,a2
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f50080e7          	jalr	-176(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001250:	46c5                	li	a3,17
    80001252:	06ee                	slli	a3,a3,0x1b
    80001254:	4719                	li	a4,6
    80001256:	412686b3          	sub	a3,a3,s2
    8000125a:	864a                	mv	a2,s2
    8000125c:	85ca                	mv	a1,s2
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f38080e7          	jalr	-200(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001268:	4729                	li	a4,10
    8000126a:	6685                	lui	a3,0x1
    8000126c:	00006617          	auipc	a2,0x6
    80001270:	d9460613          	addi	a2,a2,-620 # 80007000 <_trampoline>
    80001274:	040005b7          	lui	a1,0x4000
    80001278:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000127a:	05b2                	slli	a1,a1,0xc
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f1a080e7          	jalr	-230(ra) # 80001198 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001286:	8526                	mv	a0,s1
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	630080e7          	jalr	1584(ra) # 800018b8 <proc_mapstacks>
}
    80001290:	8526                	mv	a0,s1
    80001292:	60e2                	ld	ra,24(sp)
    80001294:	6442                	ld	s0,16(sp)
    80001296:	64a2                	ld	s1,8(sp)
    80001298:	6902                	ld	s2,0(sp)
    8000129a:	6105                	addi	sp,sp,32
    8000129c:	8082                	ret

000000008000129e <kvminit>:
{
    8000129e:	1141                	addi	sp,sp,-16
    800012a0:	e406                	sd	ra,8(sp)
    800012a2:	e022                	sd	s0,0(sp)
    800012a4:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f22080e7          	jalr	-222(ra) # 800011c8 <kvmmake>
    800012ae:	0000a797          	auipc	a5,0xa
    800012b2:	12a7b923          	sd	a0,306(a5) # 8000b3e0 <kernel_pagetable>
}
    800012b6:	60a2                	ld	ra,8(sp)
    800012b8:	6402                	ld	s0,0(sp)
    800012ba:	0141                	addi	sp,sp,16
    800012bc:	8082                	ret

00000000800012be <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012be:	715d                	addi	sp,sp,-80
    800012c0:	e486                	sd	ra,72(sp)
    800012c2:	e0a2                	sd	s0,64(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e39d                	bnez	a5,800012f0 <uvmunmap+0x32>
    800012cc:	f84a                	sd	s2,48(sp)
    800012ce:	f44e                	sd	s3,40(sp)
    800012d0:	f052                	sd	s4,32(sp)
    800012d2:	ec56                	sd	s5,24(sp)
    800012d4:	e85a                	sd	s6,16(sp)
    800012d6:	e45e                	sd	s7,8(sp)
    800012d8:	8a2a                	mv	s4,a0
    800012da:	892e                	mv	s2,a1
    800012dc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012de:	0632                	slli	a2,a2,0xc
    800012e0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	6b05                	lui	s6,0x1
    800012e8:	0935fb63          	bgeu	a1,s3,8000137e <uvmunmap+0xc0>
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	a8a9                	j	80001348 <uvmunmap+0x8a>
    800012f0:	fc26                	sd	s1,56(sp)
    800012f2:	f84a                	sd	s2,48(sp)
    800012f4:	f44e                	sd	s3,40(sp)
    800012f6:	f052                	sd	s4,32(sp)
    800012f8:	ec56                	sd	s5,24(sp)
    800012fa:	e85a                	sd	s6,16(sp)
    800012fc:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	de250513          	addi	a0,a0,-542 # 800080e0 <etext+0xe0>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	25a080e7          	jalr	602(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	dea50513          	addi	a0,a0,-534 # 800080f8 <etext+0xf8>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	24a080e7          	jalr	586(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	dea50513          	addi	a0,a0,-534 # 80008108 <etext+0x108>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	23a080e7          	jalr	570(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	df250513          	addi	a0,a0,-526 # 80008120 <etext+0x120>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	22a080e7          	jalr	554(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    8000133e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	995a                	add	s2,s2,s6
    80001344:	03397c63          	bgeu	s2,s3,8000137c <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001348:	4601                	li	a2,0
    8000134a:	85ca                	mv	a1,s2
    8000134c:	8552                	mv	a0,s4
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	cc2080e7          	jalr	-830(ra) # 80001010 <walk>
    80001356:	84aa                	mv	s1,a0
    80001358:	d95d                	beqz	a0,8000130e <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    8000135a:	6108                	ld	a0,0(a0)
    8000135c:	00157793          	andi	a5,a0,1
    80001360:	dfdd                	beqz	a5,8000131e <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001362:	3ff57793          	andi	a5,a0,1023
    80001366:	fd7784e3          	beq	a5,s7,8000132e <uvmunmap+0x70>
    if(do_free){
    8000136a:	fc0a8ae3          	beqz	s5,8000133e <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    8000136e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001370:	0532                	slli	a0,a0,0xc
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	6d8080e7          	jalr	1752(ra) # 80000a4a <kfree>
    8000137a:	b7d1                	j	8000133e <uvmunmap+0x80>
    8000137c:	74e2                	ld	s1,56(sp)
    8000137e:	7942                	ld	s2,48(sp)
    80001380:	79a2                	ld	s3,40(sp)
    80001382:	7a02                	ld	s4,32(sp)
    80001384:	6ae2                	ld	s5,24(sp)
    80001386:	6b42                	ld	s6,16(sp)
    80001388:	6ba2                	ld	s7,8(sp)
  }
}
    8000138a:	60a6                	ld	ra,72(sp)
    8000138c:	6406                	ld	s0,64(sp)
    8000138e:	6161                	addi	sp,sp,80
    80001390:	8082                	ret

0000000080001392 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001392:	1101                	addi	sp,sp,-32
    80001394:	ec06                	sd	ra,24(sp)
    80001396:	e822                	sd	s0,16(sp)
    80001398:	e426                	sd	s1,8(sp)
    8000139a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	7ac080e7          	jalr	1964(ra) # 80000b48 <kalloc>
    800013a4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a6:	c519                	beqz	a0,800013b4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	988080e7          	jalr	-1656(ra) # 80000d34 <memset>
  return pagetable;
}
    800013b4:	8526                	mv	a0,s1
    800013b6:	60e2                	ld	ra,24(sp)
    800013b8:	6442                	ld	s0,16(sp)
    800013ba:	64a2                	ld	s1,8(sp)
    800013bc:	6105                	addi	sp,sp,32
    800013be:	8082                	ret

00000000800013c0 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c0:	7179                	addi	sp,sp,-48
    800013c2:	f406                	sd	ra,40(sp)
    800013c4:	f022                	sd	s0,32(sp)
    800013c6:	ec26                	sd	s1,24(sp)
    800013c8:	e84a                	sd	s2,16(sp)
    800013ca:	e44e                	sd	s3,8(sp)
    800013cc:	e052                	sd	s4,0(sp)
    800013ce:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d0:	6785                	lui	a5,0x1
    800013d2:	04f67863          	bgeu	a2,a5,80001422 <uvmfirst+0x62>
    800013d6:	8a2a                	mv	s4,a0
    800013d8:	89ae                	mv	s3,a1
    800013da:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	76c080e7          	jalr	1900(ra) # 80000b48 <kalloc>
    800013e4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e6:	6605                	lui	a2,0x1
    800013e8:	4581                	li	a1,0
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	94a080e7          	jalr	-1718(ra) # 80000d34 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013f2:	4779                	li	a4,30
    800013f4:	86ca                	mv	a3,s2
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	cfc080e7          	jalr	-772(ra) # 800010f8 <mappages>
  memmove(mem, src, sz);
    80001404:	8626                	mv	a2,s1
    80001406:	85ce                	mv	a1,s3
    80001408:	854a                	mv	a0,s2
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	986080e7          	jalr	-1658(ra) # 80000d90 <memmove>
}
    80001412:	70a2                	ld	ra,40(sp)
    80001414:	7402                	ld	s0,32(sp)
    80001416:	64e2                	ld	s1,24(sp)
    80001418:	6942                	ld	s2,16(sp)
    8000141a:	69a2                	ld	s3,8(sp)
    8000141c:	6a02                	ld	s4,0(sp)
    8000141e:	6145                	addi	sp,sp,48
    80001420:	8082                	ret
    panic("uvmfirst: more than a page");
    80001422:	00007517          	auipc	a0,0x7
    80001426:	d1650513          	addi	a0,a0,-746 # 80008138 <etext+0x138>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	136080e7          	jalr	310(ra) # 80000560 <panic>

0000000080001432 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000143c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143e:	00b67d63          	bgeu	a2,a1,80001458 <uvmdealloc+0x26>
    80001442:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001444:	6785                	lui	a5,0x1
    80001446:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001448:	00f60733          	add	a4,a2,a5
    8000144c:	76fd                	lui	a3,0xfffff
    8000144e:	8f75                	and	a4,a4,a3
    80001450:	97ae                	add	a5,a5,a1
    80001452:	8ff5                	and	a5,a5,a3
    80001454:	00f76863          	bltu	a4,a5,80001464 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001464:	8f99                	sub	a5,a5,a4
    80001466:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001468:	4685                	li	a3,1
    8000146a:	0007861b          	sext.w	a2,a5
    8000146e:	85ba                	mv	a1,a4
    80001470:	00000097          	auipc	ra,0x0
    80001474:	e4e080e7          	jalr	-434(ra) # 800012be <uvmunmap>
    80001478:	b7c5                	j	80001458 <uvmdealloc+0x26>

000000008000147a <uvmalloc>:
  if(newsz < oldsz)
    8000147a:	0ab66b63          	bltu	a2,a1,80001530 <uvmalloc+0xb6>
{
    8000147e:	7139                	addi	sp,sp,-64
    80001480:	fc06                	sd	ra,56(sp)
    80001482:	f822                	sd	s0,48(sp)
    80001484:	ec4e                	sd	s3,24(sp)
    80001486:	e852                	sd	s4,16(sp)
    80001488:	e456                	sd	s5,8(sp)
    8000148a:	0080                	addi	s0,sp,64
    8000148c:	8aaa                	mv	s5,a0
    8000148e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001490:	6785                	lui	a5,0x1
    80001492:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001494:	95be                	add	a1,a1,a5
    80001496:	77fd                	lui	a5,0xfffff
    80001498:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	08c9fc63          	bgeu	s3,a2,80001534 <uvmalloc+0xba>
    800014a0:	f426                	sd	s1,40(sp)
    800014a2:	f04a                	sd	s2,32(sp)
    800014a4:	e05a                	sd	s6,0(sp)
    800014a6:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a8:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	69c080e7          	jalr	1692(ra) # 80000b48 <kalloc>
    800014b4:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b6:	c915                	beqz	a0,800014ea <uvmalloc+0x70>
    memset(mem, 0, PGSIZE);
    800014b8:	6605                	lui	a2,0x1
    800014ba:	4581                	li	a1,0
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	878080e7          	jalr	-1928(ra) # 80000d34 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014c4:	875a                	mv	a4,s6
    800014c6:	86a6                	mv	a3,s1
    800014c8:	6605                	lui	a2,0x1
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	c2a080e7          	jalr	-982(ra) # 800010f8 <mappages>
    800014d6:	ed05                	bnez	a0,8000150e <uvmalloc+0x94>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d8:	6785                	lui	a5,0x1
    800014da:	993e                	add	s2,s2,a5
    800014dc:	fd4968e3          	bltu	s2,s4,800014ac <uvmalloc+0x32>
  return newsz;
    800014e0:	8552                	mv	a0,s4
    800014e2:	74a2                	ld	s1,40(sp)
    800014e4:	7902                	ld	s2,32(sp)
    800014e6:	6b02                	ld	s6,0(sp)
    800014e8:	a821                	j	80001500 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f42080e7          	jalr	-190(ra) # 80001432 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	6b02                	ld	s6,0(sp)
}
    80001500:	70e2                	ld	ra,56(sp)
    80001502:	7442                	ld	s0,48(sp)
    80001504:	69e2                	ld	s3,24(sp)
    80001506:	6a42                	ld	s4,16(sp)
    80001508:	6aa2                	ld	s5,8(sp)
    8000150a:	6121                	addi	sp,sp,64
    8000150c:	8082                	ret
      kfree(mem);
    8000150e:	8526                	mv	a0,s1
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	53a080e7          	jalr	1338(ra) # 80000a4a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001518:	864e                	mv	a2,s3
    8000151a:	85ca                	mv	a1,s2
    8000151c:	8556                	mv	a0,s5
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	f14080e7          	jalr	-236(ra) # 80001432 <uvmdealloc>
      return 0;
    80001526:	4501                	li	a0,0
    80001528:	74a2                	ld	s1,40(sp)
    8000152a:	7902                	ld	s2,32(sp)
    8000152c:	6b02                	ld	s6,0(sp)
    8000152e:	bfc9                	j	80001500 <uvmalloc+0x86>
    return oldsz;
    80001530:	852e                	mv	a0,a1
}
    80001532:	8082                	ret
  return newsz;
    80001534:	8532                	mv	a0,a2
    80001536:	b7e9                	j	80001500 <uvmalloc+0x86>

0000000080001538 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001538:	7179                	addi	sp,sp,-48
    8000153a:	f406                	sd	ra,40(sp)
    8000153c:	f022                	sd	s0,32(sp)
    8000153e:	ec26                	sd	s1,24(sp)
    80001540:	e84a                	sd	s2,16(sp)
    80001542:	e44e                	sd	s3,8(sp)
    80001544:	e052                	sd	s4,0(sp)
    80001546:	1800                	addi	s0,sp,48
    80001548:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154a:	84aa                	mv	s1,a0
    8000154c:	6905                	lui	s2,0x1
    8000154e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001550:	4985                	li	s3,1
    80001552:	a829                	j	8000156c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001554:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001556:	00c79513          	slli	a0,a5,0xc
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	fde080e7          	jalr	-34(ra) # 80001538 <freewalk>
      pagetable[i] = 0;
    80001562:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001566:	04a1                	addi	s1,s1,8
    80001568:	03248163          	beq	s1,s2,8000158a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000156e:	00f7f713          	andi	a4,a5,15
    80001572:	ff3701e3          	beq	a4,s3,80001554 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001576:	8b85                	andi	a5,a5,1
    80001578:	d7fd                	beqz	a5,80001566 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157a:	00007517          	auipc	a0,0x7
    8000157e:	bde50513          	addi	a0,a0,-1058 # 80008158 <etext+0x158>
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	fde080e7          	jalr	-34(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158a:	8552                	mv	a0,s4
    8000158c:	fffff097          	auipc	ra,0xfffff
    80001590:	4be080e7          	jalr	1214(ra) # 80000a4a <kfree>
}
    80001594:	70a2                	ld	ra,40(sp)
    80001596:	7402                	ld	s0,32(sp)
    80001598:	64e2                	ld	s1,24(sp)
    8000159a:	6942                	ld	s2,16(sp)
    8000159c:	69a2                	ld	s3,8(sp)
    8000159e:	6a02                	ld	s4,0(sp)
    800015a0:	6145                	addi	sp,sp,48
    800015a2:	8082                	ret

00000000800015a4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a4:	1101                	addi	sp,sp,-32
    800015a6:	ec06                	sd	ra,24(sp)
    800015a8:	e822                	sd	s0,16(sp)
    800015aa:	e426                	sd	s1,8(sp)
    800015ac:	1000                	addi	s0,sp,32
    800015ae:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b0:	e999                	bnez	a1,800015c6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b2:	8526                	mv	a0,s1
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f84080e7          	jalr	-124(ra) # 80001538 <freewalk>
}
    800015bc:	60e2                	ld	ra,24(sp)
    800015be:	6442                	ld	s0,16(sp)
    800015c0:	64a2                	ld	s1,8(sp)
    800015c2:	6105                	addi	sp,sp,32
    800015c4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c6:	6785                	lui	a5,0x1
    800015c8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015ca:	95be                	add	a1,a1,a5
    800015cc:	4685                	li	a3,1
    800015ce:	00c5d613          	srli	a2,a1,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	cea080e7          	jalr	-790(ra) # 800012be <uvmunmap>
    800015dc:	bfd9                	j	800015b2 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	c679                	beqz	a2,800016ac <uvmcopy+0xce>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8b2a                	mv	s6,a0
    800015f8:	8aae                	mv	s5,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fe:	4601                	li	a2,0
    80001600:	85ce                	mv	a1,s3
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	a0c080e7          	jalr	-1524(ra) # 80001010 <walk>
    8000160c:	c531                	beqz	a0,80001658 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160e:	6118                	ld	a4,0(a0)
    80001610:	00177793          	andi	a5,a4,1
    80001614:	cbb1                	beqz	a5,80001668 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001616:	00a75593          	srli	a1,a4,0xa
    8000161a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	526080e7          	jalr	1318(ra) # 80000b48 <kalloc>
    8000162a:	892a                	mv	s2,a0
    8000162c:	c939                	beqz	a0,80001682 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	85de                	mv	a1,s7
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	75e080e7          	jalr	1886(ra) # 80000d90 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163a:	8726                	mv	a4,s1
    8000163c:	86ca                	mv	a3,s2
    8000163e:	6605                	lui	a2,0x1
    80001640:	85ce                	mv	a1,s3
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	ab4080e7          	jalr	-1356(ra) # 800010f8 <mappages>
    8000164c:	e515                	bnez	a0,80001678 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	6785                	lui	a5,0x1
    80001650:	99be                	add	s3,s3,a5
    80001652:	fb49e6e3          	bltu	s3,s4,800015fe <uvmcopy+0x20>
    80001656:	a081                	j	80001696 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b1050513          	addi	a0,a0,-1264 # 80008168 <etext+0x168>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	f00080e7          	jalr	-256(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b2050513          	addi	a0,a0,-1248 # 80008188 <etext+0x188>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ef0080e7          	jalr	-272(ra) # 80000560 <panic>
      kfree(mem);
    80001678:	854a                	mv	a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	3d0080e7          	jalr	976(ra) # 80000a4a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c9d613          	srli	a2,s3,0xc
    80001688:	4581                	li	a1,0
    8000168a:	8556                	mv	a0,s5
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c32080e7          	jalr	-974(ra) # 800012be <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	60a6                	ld	ra,72(sp)
    80001698:	6406                	ld	s0,64(sp)
    8000169a:	74e2                	ld	s1,56(sp)
    8000169c:	7942                	ld	s2,48(sp)
    8000169e:	79a2                	ld	s3,40(sp)
    800016a0:	7a02                	ld	s4,32(sp)
    800016a2:	6ae2                	ld	s5,24(sp)
    800016a4:	6b42                	ld	s6,16(sp)
    800016a6:	6ba2                	ld	s7,8(sp)
    800016a8:	6161                	addi	sp,sp,80
    800016aa:	8082                	ret
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret

00000000800016b0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b0:	1141                	addi	sp,sp,-16
    800016b2:	e406                	sd	ra,8(sp)
    800016b4:	e022                	sd	s0,0(sp)
    800016b6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b8:	4601                	li	a2,0
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	956080e7          	jalr	-1706(ra) # 80001010 <walk>
  if(pte == 0)
    800016c2:	c901                	beqz	a0,800016d2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c4:	611c                	ld	a5,0(a0)
    800016c6:	9bbd                	andi	a5,a5,-17
    800016c8:	e11c                	sd	a5,0(a0)
}
    800016ca:	60a2                	ld	ra,8(sp)
    800016cc:	6402                	ld	s0,0(sp)
    800016ce:	0141                	addi	sp,sp,16
    800016d0:	8082                	ret
    panic("uvmclear");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ad650513          	addi	a0,a0,-1322 # 800081a8 <etext+0x1a8>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e86080e7          	jalr	-378(ra) # 80000560 <panic>

00000000800016e2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyout+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8c2e                	mv	s8,a1
    80001700:	8a32                	mv	s4,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	85d2                	mv	a1,s4
    80001712:	41250533          	sub	a0,a0,s2
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	67a080e7          	jalr	1658(ra) # 80000d90 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001722:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	982080e7          	jalr	-1662(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyout+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyout+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyout+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176e:	caa5                	beqz	a3,800017de <copyin+0x70>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	e062                	sd	s8,0(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8b2a                	mv	s6,a0
    8000178a:	8a2e                	mv	s4,a1
    8000178c:	8c32                	mv	s8,a2
    8000178e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6a85                	lui	s5,0x1
    80001794:	a01d                	j	800017ba <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001796:	018505b3          	add	a1,a0,s8
    8000179a:	0004861b          	sext.w	a2,s1
    8000179e:	412585b3          	sub	a1,a1,s2
    800017a2:	8552                	mv	a0,s4
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	5ec080e7          	jalr	1516(ra) # 80000d90 <memmove>

    len -= n;
    800017ac:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b6:	02098263          	beqz	s3,800017da <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017be:	85ca                	mv	a1,s2
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	8f4080e7          	jalr	-1804(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    800017ca:	cd01                	beqz	a0,800017e2 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017cc:	418904b3          	sub	s1,s2,s8
    800017d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d2:	fc99f2e3          	bgeu	s3,s1,80001796 <copyin+0x28>
    800017d6:	84ce                	mv	s1,s3
    800017d8:	bf7d                	j	80001796 <copyin+0x28>
  }
  return 0;
    800017da:	4501                	li	a0,0
    800017dc:	a021                	j	800017e4 <copyin+0x76>
    800017de:	4501                	li	a0,0
}
    800017e0:	8082                	ret
      return -1;
    800017e2:	557d                	li	a0,-1
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6c02                	ld	s8,0(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret

00000000800017fc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fc:	cacd                	beqz	a3,800018ae <copyinstr+0xb2>
{
    800017fe:	715d                	addi	sp,sp,-80
    80001800:	e486                	sd	ra,72(sp)
    80001802:	e0a2                	sd	s0,64(sp)
    80001804:	fc26                	sd	s1,56(sp)
    80001806:	f84a                	sd	s2,48(sp)
    80001808:	f44e                	sd	s3,40(sp)
    8000180a:	f052                	sd	s4,32(sp)
    8000180c:	ec56                	sd	s5,24(sp)
    8000180e:	e85a                	sd	s6,16(sp)
    80001810:	e45e                	sd	s7,8(sp)
    80001812:	0880                	addi	s0,sp,80
    80001814:	8a2a                	mv	s4,a0
    80001816:	8b2e                	mv	s6,a1
    80001818:	8bb2                	mv	s7,a2
    8000181a:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    8000181c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181e:	6985                	lui	s3,0x1
    80001820:	a825                	j	80001858 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001822:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001826:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret
    80001844:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    80001848:	9742                	add	a4,a4,a6
      --max;
    8000184a:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    8000184e:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001852:	04e58663          	beq	a1,a4,8000189e <copyinstr+0xa2>
{
    80001856:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    80001858:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000185c:	85a6                	mv	a1,s1
    8000185e:	8552                	mv	a0,s4
    80001860:	00000097          	auipc	ra,0x0
    80001864:	856080e7          	jalr	-1962(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    80001868:	cd0d                	beqz	a0,800018a2 <copyinstr+0xa6>
    n = PGSIZE - (srcva - va0);
    8000186a:	417486b3          	sub	a3,s1,s7
    8000186e:	96ce                	add	a3,a3,s3
    if(n > max)
    80001870:	00d97363          	bgeu	s2,a3,80001876 <copyinstr+0x7a>
    80001874:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001876:	955e                	add	a0,a0,s7
    80001878:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000187a:	c695                	beqz	a3,800018a6 <copyinstr+0xaa>
    8000187c:	87da                	mv	a5,s6
    8000187e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001880:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001884:	96da                	add	a3,a3,s6
    80001886:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001888:	00f60733          	add	a4,a2,a5
    8000188c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd2580>
    80001890:	db49                	beqz	a4,80001822 <copyinstr+0x26>
        *dst = *p;
    80001892:	00e78023          	sb	a4,0(a5)
      dst++;
    80001896:	0785                	addi	a5,a5,1
    while(n > 0){
    80001898:	fed797e3          	bne	a5,a3,80001886 <copyinstr+0x8a>
    8000189c:	b765                	j	80001844 <copyinstr+0x48>
    8000189e:	4781                	li	a5,0
    800018a0:	b761                	j	80001828 <copyinstr+0x2c>
      return -1;
    800018a2:	557d                	li	a0,-1
    800018a4:	b769                	j	8000182e <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    800018a6:	6b85                	lui	s7,0x1
    800018a8:	9ba6                	add	s7,s7,s1
    800018aa:	87da                	mv	a5,s6
    800018ac:	b76d                	j	80001856 <copyinstr+0x5a>
  int got_null = 0;
    800018ae:	4781                	li	a5,0
  if(got_null){
    800018b0:	37fd                	addiw	a5,a5,-1
    800018b2:	0007851b          	sext.w	a0,a5
}
    800018b6:	8082                	ret

00000000800018b8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800018b8:	7139                	addi	sp,sp,-64
    800018ba:	fc06                	sd	ra,56(sp)
    800018bc:	f822                	sd	s0,48(sp)
    800018be:	f426                	sd	s1,40(sp)
    800018c0:	f04a                	sd	s2,32(sp)
    800018c2:	ec4e                	sd	s3,24(sp)
    800018c4:	e852                	sd	s4,16(sp)
    800018c6:	e456                	sd	s5,8(sp)
    800018c8:	e05a                	sd	s6,0(sp)
    800018ca:	0080                	addi	s0,sp,64
    800018cc:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800018ce:	00013497          	auipc	s1,0x13
    800018d2:	9d248493          	addi	s1,s1,-1582 # 800142a0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800018d6:	8b26                	mv	s6,s1
    800018d8:	00874937          	lui	s2,0x874
    800018dc:	ecb90913          	addi	s2,s2,-309 # 873ecb <_entry-0x7f78c135>
    800018e0:	0932                	slli	s2,s2,0xc
    800018e2:	de390913          	addi	s2,s2,-541
    800018e6:	093a                	slli	s2,s2,0xe
    800018e8:	13590913          	addi	s2,s2,309
    800018ec:	0932                	slli	s2,s2,0xc
    800018ee:	21d90913          	addi	s2,s2,541
    800018f2:	040009b7          	lui	s3,0x4000
    800018f6:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800018f8:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018fa:	00020a97          	auipc	s5,0x20
    800018fe:	da6a8a93          	addi	s5,s5,-602 # 800216a0 <tickslock>
    char *pa = kalloc();
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	246080e7          	jalr	582(ra) # 80000b48 <kalloc>
    8000190a:	862a                	mv	a2,a0
    if (pa == 0)
    8000190c:	c121                	beqz	a0,8000194c <proc_mapstacks+0x94>
    uint64 va = KSTACK((int)(p - proc));
    8000190e:	416485b3          	sub	a1,s1,s6
    80001912:	8591                	srai	a1,a1,0x4
    80001914:	032585b3          	mul	a1,a1,s2
    80001918:	2585                	addiw	a1,a1,1
    8000191a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000191e:	4719                	li	a4,6
    80001920:	6685                	lui	a3,0x1
    80001922:	40b985b3          	sub	a1,s3,a1
    80001926:	8552                	mv	a0,s4
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	870080e7          	jalr	-1936(ra) # 80001198 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001930:	35048493          	addi	s1,s1,848
    80001934:	fd5497e3          	bne	s1,s5,80001902 <proc_mapstacks+0x4a>
  }
}
    80001938:	70e2                	ld	ra,56(sp)
    8000193a:	7442                	ld	s0,48(sp)
    8000193c:	74a2                	ld	s1,40(sp)
    8000193e:	7902                	ld	s2,32(sp)
    80001940:	69e2                	ld	s3,24(sp)
    80001942:	6a42                	ld	s4,16(sp)
    80001944:	6aa2                	ld	s5,8(sp)
    80001946:	6b02                	ld	s6,0(sp)
    80001948:	6121                	addi	sp,sp,64
    8000194a:	8082                	ret
      panic("kalloc");
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	86c50513          	addi	a0,a0,-1940 # 800081b8 <etext+0x1b8>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	c0c080e7          	jalr	-1012(ra) # 80000560 <panic>

000000008000195c <rand>:
uint64 rand(void)
{
    8000195c:	1141                	addi	sp,sp,-16
    8000195e:	e422                	sd	s0,8(sp)
    80001960:	0800                	addi	s0,sp,16
  static uint64 seed = 12345;         // Seed value (you can change this)
  seed = (seed * 48271) % 2147483647; // LCG formula
    80001962:	0000a717          	auipc	a4,0xa
    80001966:	9e670713          	addi	a4,a4,-1562 # 8000b348 <seed.2>
    8000196a:	6308                	ld	a0,0(a4)
    8000196c:	67b1                	lui	a5,0xc
    8000196e:	c8f78793          	addi	a5,a5,-881 # bc8f <_entry-0x7fff4371>
    80001972:	02f50533          	mul	a0,a0,a5
    80001976:	800007b7          	lui	a5,0x80000
    8000197a:	fff7c793          	not	a5,a5
    8000197e:	02f57533          	remu	a0,a0,a5
    80001982:	e308                	sd	a0,0(a4)
  return seed;
}
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <procinit>:
// initialize the proc table.
void procinit(void)
{
    8000198a:	7139                	addi	sp,sp,-64
    8000198c:	fc06                	sd	ra,56(sp)
    8000198e:	f822                	sd	s0,48(sp)
    80001990:	f426                	sd	s1,40(sp)
    80001992:	f04a                	sd	s2,32(sp)
    80001994:	ec4e                	sd	s3,24(sp)
    80001996:	e852                	sd	s4,16(sp)
    80001998:	e456                	sd	s5,8(sp)
    8000199a:	e05a                	sd	s6,0(sp)
    8000199c:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    8000199e:	00007597          	auipc	a1,0x7
    800019a2:	82258593          	addi	a1,a1,-2014 # 800081c0 <etext+0x1c0>
    800019a6:	00012517          	auipc	a0,0x12
    800019aa:	cba50513          	addi	a0,a0,-838 # 80013660 <pid_lock>
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	1fa080e7          	jalr	506(ra) # 80000ba8 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019b6:	00007597          	auipc	a1,0x7
    800019ba:	81258593          	addi	a1,a1,-2030 # 800081c8 <etext+0x1c8>
    800019be:	00012517          	auipc	a0,0x12
    800019c2:	cba50513          	addi	a0,a0,-838 # 80013678 <wait_lock>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	1e2080e7          	jalr	482(ra) # 80000ba8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019ce:	00013497          	auipc	s1,0x13
    800019d2:	8d248493          	addi	s1,s1,-1838 # 800142a0 <proc>
  {
    initlock(&p->lock, "proc");
    800019d6:	00007b17          	auipc	s6,0x7
    800019da:	802b0b13          	addi	s6,s6,-2046 # 800081d8 <etext+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    800019de:	8aa6                	mv	s5,s1
    800019e0:	00874937          	lui	s2,0x874
    800019e4:	ecb90913          	addi	s2,s2,-309 # 873ecb <_entry-0x7f78c135>
    800019e8:	0932                	slli	s2,s2,0xc
    800019ea:	de390913          	addi	s2,s2,-541
    800019ee:	093a                	slli	s2,s2,0xe
    800019f0:	13590913          	addi	s2,s2,309
    800019f4:	0932                	slli	s2,s2,0xc
    800019f6:	21d90913          	addi	s2,s2,541
    800019fa:	040009b7          	lui	s3,0x4000
    800019fe:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001a00:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a02:	00020a17          	auipc	s4,0x20
    80001a06:	c9ea0a13          	addi	s4,s4,-866 # 800216a0 <tickslock>
    initlock(&p->lock, "proc");
    80001a0a:	85da                	mv	a1,s6
    80001a0c:	8526                	mv	a0,s1
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	19a080e7          	jalr	410(ra) # 80000ba8 <initlock>
    p->state = UNUSED;
    80001a16:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a1a:	415487b3          	sub	a5,s1,s5
    80001a1e:	8791                	srai	a5,a5,0x4
    80001a20:	032787b3          	mul	a5,a5,s2
    80001a24:	2785                	addiw	a5,a5,1 # ffffffff80000001 <end+0xfffffffefffd3581>
    80001a26:	00d7979b          	slliw	a5,a5,0xd
    80001a2a:	40f987b3          	sub	a5,s3,a5
    80001a2e:	20f4bc23          	sd	a5,536(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a32:	35048493          	addi	s1,s1,848
    80001a36:	fd449ae3          	bne	s1,s4,80001a0a <procinit+0x80>
  }
}
    80001a3a:	70e2                	ld	ra,56(sp)
    80001a3c:	7442                	ld	s0,48(sp)
    80001a3e:	74a2                	ld	s1,40(sp)
    80001a40:	7902                	ld	s2,32(sp)
    80001a42:	69e2                	ld	s3,24(sp)
    80001a44:	6a42                	ld	s4,16(sp)
    80001a46:	6aa2                	ld	s5,8(sp)
    80001a48:	6b02                	ld	s6,0(sp)
    80001a4a:	6121                	addi	sp,sp,64
    80001a4c:	8082                	ret

0000000080001a4e <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001a4e:	1141                	addi	sp,sp,-16
    80001a50:	e422                	sd	s0,8(sp)
    80001a52:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a54:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a56:	2501                	sext.w	a0,a0
    80001a58:	6422                	ld	s0,8(sp)
    80001a5a:	0141                	addi	sp,sp,16
    80001a5c:	8082                	ret

0000000080001a5e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e422                	sd	s0,8(sp)
    80001a62:	0800                	addi	s0,sp,16
    80001a64:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a66:	2781                	sext.w	a5,a5
    80001a68:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a6a:	00012517          	auipc	a0,0x12
    80001a6e:	c2650513          	addi	a0,a0,-986 # 80013690 <cpus>
    80001a72:	953e                	add	a0,a0,a5
    80001a74:	6422                	ld	s0,8(sp)
    80001a76:	0141                	addi	sp,sp,16
    80001a78:	8082                	ret

0000000080001a7a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001a7a:	1101                	addi	sp,sp,-32
    80001a7c:	ec06                	sd	ra,24(sp)
    80001a7e:	e822                	sd	s0,16(sp)
    80001a80:	e426                	sd	s1,8(sp)
    80001a82:	1000                	addi	s0,sp,32
  push_off();
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	168080e7          	jalr	360(ra) # 80000bec <push_off>
    80001a8c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a8e:	2781                	sext.w	a5,a5
    80001a90:	079e                	slli	a5,a5,0x7
    80001a92:	00012717          	auipc	a4,0x12
    80001a96:	bce70713          	addi	a4,a4,-1074 # 80013660 <pid_lock>
    80001a9a:	97ba                	add	a5,a5,a4
    80001a9c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	1ee080e7          	jalr	494(ra) # 80000c8c <pop_off>
  return p;
}
    80001aa6:	8526                	mv	a0,s1
    80001aa8:	60e2                	ld	ra,24(sp)
    80001aaa:	6442                	ld	s0,16(sp)
    80001aac:	64a2                	ld	s1,8(sp)
    80001aae:	6105                	addi	sp,sp,32
    80001ab0:	8082                	ret

0000000080001ab2 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ab2:	1141                	addi	sp,sp,-16
    80001ab4:	e406                	sd	ra,8(sp)
    80001ab6:	e022                	sd	s0,0(sp)
    80001ab8:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001aba:	00000097          	auipc	ra,0x0
    80001abe:	fc0080e7          	jalr	-64(ra) # 80001a7a <myproc>
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	22a080e7          	jalr	554(ra) # 80000cec <release>

  if (first)
    80001aca:	0000a797          	auipc	a5,0xa
    80001ace:	8767a783          	lw	a5,-1930(a5) # 8000b340 <first.1>
    80001ad2:	eb89                	bnez	a5,80001ae4 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ad4:	00001097          	auipc	ra,0x1
    80001ad8:	1f8080e7          	jalr	504(ra) # 80002ccc <usertrapret>
}
    80001adc:	60a2                	ld	ra,8(sp)
    80001ade:	6402                	ld	s0,0(sp)
    80001ae0:	0141                	addi	sp,sp,16
    80001ae2:	8082                	ret
    first = 0;
    80001ae4:	0000a797          	auipc	a5,0xa
    80001ae8:	8407ae23          	sw	zero,-1956(a5) # 8000b340 <first.1>
    fsinit(ROOTDEV);
    80001aec:	4505                	li	a0,1
    80001aee:	00002097          	auipc	ra,0x2
    80001af2:	180080e7          	jalr	384(ra) # 80003c6e <fsinit>
    80001af6:	bff9                	j	80001ad4 <forkret+0x22>

0000000080001af8 <allocpid>:
{
    80001af8:	1101                	addi	sp,sp,-32
    80001afa:	ec06                	sd	ra,24(sp)
    80001afc:	e822                	sd	s0,16(sp)
    80001afe:	e426                	sd	s1,8(sp)
    80001b00:	e04a                	sd	s2,0(sp)
    80001b02:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b04:	00012917          	auipc	s2,0x12
    80001b08:	b5c90913          	addi	s2,s2,-1188 # 80013660 <pid_lock>
    80001b0c:	854a                	mv	a0,s2
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	12a080e7          	jalr	298(ra) # 80000c38 <acquire>
  pid = nextpid;
    80001b16:	0000a797          	auipc	a5,0xa
    80001b1a:	83a78793          	addi	a5,a5,-1990 # 8000b350 <nextpid>
    80001b1e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b20:	0014871b          	addiw	a4,s1,1
    80001b24:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b26:	854a                	mv	a0,s2
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	1c4080e7          	jalr	452(ra) # 80000cec <release>
}
    80001b30:	8526                	mv	a0,s1
    80001b32:	60e2                	ld	ra,24(sp)
    80001b34:	6442                	ld	s0,16(sp)
    80001b36:	64a2                	ld	s1,8(sp)
    80001b38:	6902                	ld	s2,0(sp)
    80001b3a:	6105                	addi	sp,sp,32
    80001b3c:	8082                	ret

0000000080001b3e <proc_pagetable>:
{
    80001b3e:	1101                	addi	sp,sp,-32
    80001b40:	ec06                	sd	ra,24(sp)
    80001b42:	e822                	sd	s0,16(sp)
    80001b44:	e426                	sd	s1,8(sp)
    80001b46:	e04a                	sd	s2,0(sp)
    80001b48:	1000                	addi	s0,sp,32
    80001b4a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b4c:	00000097          	auipc	ra,0x0
    80001b50:	846080e7          	jalr	-1978(ra) # 80001392 <uvmcreate>
    80001b54:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001b56:	c121                	beqz	a0,80001b96 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b58:	4729                	li	a4,10
    80001b5a:	00005697          	auipc	a3,0x5
    80001b5e:	4a668693          	addi	a3,a3,1190 # 80007000 <_trampoline>
    80001b62:	6605                	lui	a2,0x1
    80001b64:	040005b7          	lui	a1,0x4000
    80001b68:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b6a:	05b2                	slli	a1,a1,0xc
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	58c080e7          	jalr	1420(ra) # 800010f8 <mappages>
    80001b74:	02054863          	bltz	a0,80001ba4 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b78:	4719                	li	a4,6
    80001b7a:	23093683          	ld	a3,560(s2)
    80001b7e:	6605                	lui	a2,0x1
    80001b80:	020005b7          	lui	a1,0x2000
    80001b84:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b86:	05b6                	slli	a1,a1,0xd
    80001b88:	8526                	mv	a0,s1
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	56e080e7          	jalr	1390(ra) # 800010f8 <mappages>
    80001b92:	02054163          	bltz	a0,80001bb4 <proc_pagetable+0x76>
}
    80001b96:	8526                	mv	a0,s1
    80001b98:	60e2                	ld	ra,24(sp)
    80001b9a:	6442                	ld	s0,16(sp)
    80001b9c:	64a2                	ld	s1,8(sp)
    80001b9e:	6902                	ld	s2,0(sp)
    80001ba0:	6105                	addi	sp,sp,32
    80001ba2:	8082                	ret
    uvmfree(pagetable, 0);
    80001ba4:	4581                	li	a1,0
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	00000097          	auipc	ra,0x0
    80001bac:	9fc080e7          	jalr	-1540(ra) # 800015a4 <uvmfree>
    return 0;
    80001bb0:	4481                	li	s1,0
    80001bb2:	b7d5                	j	80001b96 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb4:	4681                	li	a3,0
    80001bb6:	4605                	li	a2,1
    80001bb8:	040005b7          	lui	a1,0x4000
    80001bbc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bbe:	05b2                	slli	a1,a1,0xc
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	6fc080e7          	jalr	1788(ra) # 800012be <uvmunmap>
    uvmfree(pagetable, 0);
    80001bca:	4581                	li	a1,0
    80001bcc:	8526                	mv	a0,s1
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	9d6080e7          	jalr	-1578(ra) # 800015a4 <uvmfree>
    return 0;
    80001bd6:	4481                	li	s1,0
    80001bd8:	bf7d                	j	80001b96 <proc_pagetable+0x58>

0000000080001bda <proc_freepagetable>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	e04a                	sd	s2,0(sp)
    80001be4:	1000                	addi	s0,sp,32
    80001be6:	84aa                	mv	s1,a0
    80001be8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bea:	4681                	li	a3,0
    80001bec:	4605                	li	a2,1
    80001bee:	040005b7          	lui	a1,0x4000
    80001bf2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bf4:	05b2                	slli	a1,a1,0xc
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	6c8080e7          	jalr	1736(ra) # 800012be <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bfe:	4681                	li	a3,0
    80001c00:	4605                	li	a2,1
    80001c02:	020005b7          	lui	a1,0x2000
    80001c06:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c08:	05b6                	slli	a1,a1,0xd
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	6b2080e7          	jalr	1714(ra) # 800012be <uvmunmap>
  uvmfree(pagetable, sz);
    80001c14:	85ca                	mv	a1,s2
    80001c16:	8526                	mv	a0,s1
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	98c080e7          	jalr	-1652(ra) # 800015a4 <uvmfree>
}
    80001c20:	60e2                	ld	ra,24(sp)
    80001c22:	6442                	ld	s0,16(sp)
    80001c24:	64a2                	ld	s1,8(sp)
    80001c26:	6902                	ld	s2,0(sp)
    80001c28:	6105                	addi	sp,sp,32
    80001c2a:	8082                	ret

0000000080001c2c <freeproc>:
{
    80001c2c:	1101                	addi	sp,sp,-32
    80001c2e:	ec06                	sd	ra,24(sp)
    80001c30:	e822                	sd	s0,16(sp)
    80001c32:	e426                	sd	s1,8(sp)
    80001c34:	1000                	addi	s0,sp,32
    80001c36:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c38:	23053503          	ld	a0,560(a0)
    80001c3c:	c509                	beqz	a0,80001c46 <freeproc+0x1a>
    kfree((void *)p->trapframe);
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	e0c080e7          	jalr	-500(ra) # 80000a4a <kfree>
  p->trapframe = 0;
    80001c46:	2204b823          	sd	zero,560(s1)
  if (p->pagetable)
    80001c4a:	2284b503          	ld	a0,552(s1)
    80001c4e:	c519                	beqz	a0,80001c5c <freeproc+0x30>
    proc_freepagetable(p->pagetable, p->sz);
    80001c50:	2204b583          	ld	a1,544(s1)
    80001c54:	00000097          	auipc	ra,0x0
    80001c58:	f86080e7          	jalr	-122(ra) # 80001bda <proc_freepagetable>
  p->pagetable = 0;
    80001c5c:	2204b423          	sd	zero,552(s1)
  p->sz = 0;
    80001c60:	2204b023          	sd	zero,544(s1)
  p->pid = 0;
    80001c64:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c68:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c6c:	32048823          	sb	zero,816(s1)
  p->chan = 0;
    80001c70:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c74:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c78:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c7c:	0004ac23          	sw	zero,24(s1)
  for (int x = 0; x <= 26; x++)
    80001c80:	04048793          	addi	a5,s1,64
    80001c84:	0ac48713          	addi	a4,s1,172
    p->syscall_count[x] = 0;
    80001c88:	0007a023          	sw	zero,0(a5)
  for (int x = 0; x <= 26; x++)
    80001c8c:	0791                	addi	a5,a5,4
    80001c8e:	fee79de3          	bne	a5,a4,80001c88 <freeproc+0x5c>
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret

0000000080001c9c <allocproc>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	e04a                	sd	s2,0(sp)
    80001ca6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ca8:	00012497          	auipc	s1,0x12
    80001cac:	5f848493          	addi	s1,s1,1528 # 800142a0 <proc>
    80001cb0:	00020917          	auipc	s2,0x20
    80001cb4:	9f090913          	addi	s2,s2,-1552 # 800216a0 <tickslock>
    acquire(&p->lock);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	f7e080e7          	jalr	-130(ra) # 80000c38 <acquire>
    if (p->state == UNUSED)
    80001cc2:	4c9c                	lw	a5,24(s1)
    80001cc4:	cf81                	beqz	a5,80001cdc <allocproc+0x40>
      release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	024080e7          	jalr	36(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001cd0:	35048493          	addi	s1,s1,848
    80001cd4:	ff2492e3          	bne	s1,s2,80001cb8 <allocproc+0x1c>
  return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	a859                	j	80001d70 <allocproc+0xd4>
  p->pid = allocpid();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	e1c080e7          	jalr	-484(ra) # 80001af8 <allocpid>
    80001ce4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ce6:	4785                	li	a5,1
    80001ce8:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	e5e080e7          	jalr	-418(ra) # 80000b48 <kalloc>
    80001cf2:	892a                	mv	s2,a0
    80001cf4:	22a4b823          	sd	a0,560(s1)
    80001cf8:	c159                	beqz	a0,80001d7e <allocproc+0xe2>
  p->pagetable = proc_pagetable(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	e42080e7          	jalr	-446(ra) # 80001b3e <proc_pagetable>
    80001d04:	892a                	mv	s2,a0
    80001d06:	22a4b423          	sd	a0,552(s1)
  if (p->pagetable == 0)
    80001d0a:	c551                	beqz	a0,80001d96 <allocproc+0xfa>
  memset(&p->context, 0, sizeof(p->context));
    80001d0c:	07000613          	li	a2,112
    80001d10:	4581                	li	a1,0
    80001d12:	23848513          	addi	a0,s1,568
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	01e080e7          	jalr	30(ra) # 80000d34 <memset>
  p->context.ra = (uint64)forkret;
    80001d1e:	00000797          	auipc	a5,0x0
    80001d22:	d9478793          	addi	a5,a5,-620 # 80001ab2 <forkret>
    80001d26:	22f4bc23          	sd	a5,568(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d2a:	2184b783          	ld	a5,536(s1)
    80001d2e:	6705                	lui	a4,0x1
    80001d30:	97ba                	add	a5,a5,a4
    80001d32:	24f4b023          	sd	a5,576(s1)
  p->rtime = 0;
    80001d36:	3404a023          	sw	zero,832(s1)
  p->etime = 0;
    80001d3a:	3404a423          	sw	zero,840(s1)
  p->ctime = ticks;
    80001d3e:	00009797          	auipc	a5,0x9
    80001d42:	6b67a783          	lw	a5,1718(a5) # 8000b3f4 <ticks>
    80001d46:	34f4a223          	sw	a5,836(s1)
  p->tickets = 1;
    80001d4a:	4705                	li	a4,1
    80001d4c:	0ce4a023          	sw	a4,192(s1)
  p->ticks = 0;
    80001d50:	0e04a023          	sw	zero,224(s1)
  p->arrival_time = ticks;// to add new process in the end;
    80001d54:	1782                	slli	a5,a5,0x20
    80001d56:	9381                	srli	a5,a5,0x20
    80001d58:	e4fc                	sd	a5,200(s1)
  p->priority = 0;
    80001d5a:	0c04ac23          	sw	zero,216(s1)
  for (int x = 0; x <= 26; x++)
    80001d5e:	04048793          	addi	a5,s1,64
    80001d62:	0ac48713          	addi	a4,s1,172
    p->syscall_count[x] = 0;
    80001d66:	0007a023          	sw	zero,0(a5)
  for (int x = 0; x <= 26; x++)
    80001d6a:	0791                	addi	a5,a5,4
    80001d6c:	fee79de3          	bne	a5,a4,80001d66 <allocproc+0xca>
}
    80001d70:	8526                	mv	a0,s1
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6902                	ld	s2,0(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret
    freeproc(p);
    80001d7e:	8526                	mv	a0,s1
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	eac080e7          	jalr	-340(ra) # 80001c2c <freeproc>
    release(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f62080e7          	jalr	-158(ra) # 80000cec <release>
    return 0;
    80001d92:	84ca                	mv	s1,s2
    80001d94:	bff1                	j	80001d70 <allocproc+0xd4>
    freeproc(p);
    80001d96:	8526                	mv	a0,s1
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	e94080e7          	jalr	-364(ra) # 80001c2c <freeproc>
    release(&p->lock);
    80001da0:	8526                	mv	a0,s1
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	f4a080e7          	jalr	-182(ra) # 80000cec <release>
    return 0;
    80001daa:	84ca                	mv	s1,s2
    80001dac:	b7d1                	j	80001d70 <allocproc+0xd4>

0000000080001dae <userinit>:
{
    80001dae:	1101                	addi	sp,sp,-32
    80001db0:	ec06                	sd	ra,24(sp)
    80001db2:	e822                	sd	s0,16(sp)
    80001db4:	e426                	sd	s1,8(sp)
    80001db6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	ee4080e7          	jalr	-284(ra) # 80001c9c <allocproc>
    80001dc0:	84aa                	mv	s1,a0
  initproc = p;
    80001dc2:	00009797          	auipc	a5,0x9
    80001dc6:	62a7b323          	sd	a0,1574(a5) # 8000b3e8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dca:	03400613          	li	a2,52
    80001dce:	00009597          	auipc	a1,0x9
    80001dd2:	59258593          	addi	a1,a1,1426 # 8000b360 <initcode>
    80001dd6:	22853503          	ld	a0,552(a0)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	5e6080e7          	jalr	1510(ra) # 800013c0 <uvmfirst>
  p->sz = PGSIZE;
    80001de2:	6785                	lui	a5,0x1
    80001de4:	22f4b023          	sd	a5,544(s1)
  p->trapframe->epc = 0;     // user program counter
    80001de8:	2304b703          	ld	a4,560(s1)
    80001dec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001df0:	2304b703          	ld	a4,560(s1)
    80001df4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df6:	4641                	li	a2,16
    80001df8:	00006597          	auipc	a1,0x6
    80001dfc:	3e858593          	addi	a1,a1,1000 # 800081e0 <etext+0x1e0>
    80001e00:	33048513          	addi	a0,s1,816
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	072080e7          	jalr	114(ra) # 80000e76 <safestrcpy>
  p->cwd = namei("/");
    80001e0c:	00006517          	auipc	a0,0x6
    80001e10:	3e450513          	addi	a0,a0,996 # 800081f0 <etext+0x1f0>
    80001e14:	00003097          	auipc	ra,0x3
    80001e18:	8ac080e7          	jalr	-1876(ra) # 800046c0 <namei>
    80001e1c:	32a4b423          	sd	a0,808(s1)
  p->state = RUNNABLE;
    80001e20:	478d                	li	a5,3
    80001e22:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e24:	8526                	mv	a0,s1
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	ec6080e7          	jalr	-314(ra) # 80000cec <release>
}
    80001e2e:	60e2                	ld	ra,24(sp)
    80001e30:	6442                	ld	s0,16(sp)
    80001e32:	64a2                	ld	s1,8(sp)
    80001e34:	6105                	addi	sp,sp,32
    80001e36:	8082                	ret

0000000080001e38 <growproc>:
{
    80001e38:	1101                	addi	sp,sp,-32
    80001e3a:	ec06                	sd	ra,24(sp)
    80001e3c:	e822                	sd	s0,16(sp)
    80001e3e:	e426                	sd	s1,8(sp)
    80001e40:	e04a                	sd	s2,0(sp)
    80001e42:	1000                	addi	s0,sp,32
    80001e44:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e46:	00000097          	auipc	ra,0x0
    80001e4a:	c34080e7          	jalr	-972(ra) # 80001a7a <myproc>
    80001e4e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e50:	22053583          	ld	a1,544(a0)
  if (n > 0)
    80001e54:	01204d63          	bgtz	s2,80001e6e <growproc+0x36>
  else if (n < 0)
    80001e58:	02094863          	bltz	s2,80001e88 <growproc+0x50>
  p->sz = sz;
    80001e5c:	22b4b023          	sd	a1,544(s1)
  return 0;
    80001e60:	4501                	li	a0,0
}
    80001e62:	60e2                	ld	ra,24(sp)
    80001e64:	6442                	ld	s0,16(sp)
    80001e66:	64a2                	ld	s1,8(sp)
    80001e68:	6902                	ld	s2,0(sp)
    80001e6a:	6105                	addi	sp,sp,32
    80001e6c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e6e:	4691                	li	a3,4
    80001e70:	00b90633          	add	a2,s2,a1
    80001e74:	22853503          	ld	a0,552(a0)
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	602080e7          	jalr	1538(ra) # 8000147a <uvmalloc>
    80001e80:	85aa                	mv	a1,a0
    80001e82:	fd69                	bnez	a0,80001e5c <growproc+0x24>
      return -1;
    80001e84:	557d                	li	a0,-1
    80001e86:	bff1                	j	80001e62 <growproc+0x2a>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e88:	00b90633          	add	a2,s2,a1
    80001e8c:	22853503          	ld	a0,552(a0)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	5a2080e7          	jalr	1442(ra) # 80001432 <uvmdealloc>
    80001e98:	85aa                	mv	a1,a0
    80001e9a:	b7c9                	j	80001e5c <growproc+0x24>

0000000080001e9c <fork>:
{
    80001e9c:	7139                	addi	sp,sp,-64
    80001e9e:	fc06                	sd	ra,56(sp)
    80001ea0:	f822                	sd	s0,48(sp)
    80001ea2:	f04a                	sd	s2,32(sp)
    80001ea4:	e456                	sd	s5,8(sp)
    80001ea6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	bd2080e7          	jalr	-1070(ra) # 80001a7a <myproc>
    80001eb0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	dea080e7          	jalr	-534(ra) # 80001c9c <allocproc>
    80001eba:	12050563          	beqz	a0,80001fe4 <fork+0x148>
    80001ebe:	ec4e                	sd	s3,24(sp)
    80001ec0:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ec2:	220ab603          	ld	a2,544(s5)
    80001ec6:	22853583          	ld	a1,552(a0)
    80001eca:	228ab503          	ld	a0,552(s5)
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	710080e7          	jalr	1808(ra) # 800015de <uvmcopy>
    80001ed6:	04054a63          	bltz	a0,80001f2a <fork+0x8e>
    80001eda:	f426                	sd	s1,40(sp)
    80001edc:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001ede:	220ab783          	ld	a5,544(s5)
    80001ee2:	22f9b023          	sd	a5,544(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ee6:	230ab683          	ld	a3,560(s5)
    80001eea:	87b6                	mv	a5,a3
    80001eec:	2309b703          	ld	a4,560(s3)
    80001ef0:	12068693          	addi	a3,a3,288
    80001ef4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ef8:	6788                	ld	a0,8(a5)
    80001efa:	6b8c                	ld	a1,16(a5)
    80001efc:	6f90                	ld	a2,24(a5)
    80001efe:	01073023          	sd	a6,0(a4)
    80001f02:	e708                	sd	a0,8(a4)
    80001f04:	eb0c                	sd	a1,16(a4)
    80001f06:	ef10                	sd	a2,24(a4)
    80001f08:	02078793          	addi	a5,a5,32
    80001f0c:	02070713          	addi	a4,a4,32
    80001f10:	fed792e3          	bne	a5,a3,80001ef4 <fork+0x58>
  np->trapframe->a0 = 0;
    80001f14:	2309b783          	ld	a5,560(s3)
    80001f18:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f1c:	2a8a8493          	addi	s1,s5,680
    80001f20:	2a898913          	addi	s2,s3,680
    80001f24:	328a8a13          	addi	s4,s5,808
    80001f28:	a015                	j	80001f4c <fork+0xb0>
    freeproc(np);
    80001f2a:	854e                	mv	a0,s3
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	d00080e7          	jalr	-768(ra) # 80001c2c <freeproc>
    release(&np->lock);
    80001f34:	854e                	mv	a0,s3
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	db6080e7          	jalr	-586(ra) # 80000cec <release>
    return -1;
    80001f3e:	597d                	li	s2,-1
    80001f40:	69e2                	ld	s3,24(sp)
    80001f42:	a851                	j	80001fd6 <fork+0x13a>
  for (i = 0; i < NOFILE; i++)
    80001f44:	04a1                	addi	s1,s1,8
    80001f46:	0921                	addi	s2,s2,8
    80001f48:	01448b63          	beq	s1,s4,80001f5e <fork+0xc2>
    if (p->ofile[i])
    80001f4c:	6088                	ld	a0,0(s1)
    80001f4e:	d97d                	beqz	a0,80001f44 <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f50:	00003097          	auipc	ra,0x3
    80001f54:	de8080e7          	jalr	-536(ra) # 80004d38 <filedup>
    80001f58:	00a93023          	sd	a0,0(s2)
    80001f5c:	b7e5                	j	80001f44 <fork+0xa8>
  np->cwd = idup(p->cwd);
    80001f5e:	328ab503          	ld	a0,808(s5)
    80001f62:	00002097          	auipc	ra,0x2
    80001f66:	f52080e7          	jalr	-174(ra) # 80003eb4 <idup>
    80001f6a:	32a9b423          	sd	a0,808(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f6e:	4641                	li	a2,16
    80001f70:	330a8593          	addi	a1,s5,816
    80001f74:	33098513          	addi	a0,s3,816
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	efe080e7          	jalr	-258(ra) # 80000e76 <safestrcpy>
  np->tickets = p->tickets;
    80001f80:	0c0aa783          	lw	a5,192(s5)
    80001f84:	0cf9a023          	sw	a5,192(s3)
  pid = np->pid;
    80001f88:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001f8c:	854e                	mv	a0,s3
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	d5e080e7          	jalr	-674(ra) # 80000cec <release>
  acquire(&wait_lock);
    80001f96:	00011497          	auipc	s1,0x11
    80001f9a:	6e248493          	addi	s1,s1,1762 # 80013678 <wait_lock>
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	c98080e7          	jalr	-872(ra) # 80000c38 <acquire>
  np->parent = p;
    80001fa8:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001fac:	8526                	mv	a0,s1
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	d3e080e7          	jalr	-706(ra) # 80000cec <release>
  acquire(&np->lock);
    80001fb6:	854e                	mv	a0,s3
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	c80080e7          	jalr	-896(ra) # 80000c38 <acquire>
  np->state = RUNNABLE;
    80001fc0:	478d                	li	a5,3
    80001fc2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	d24080e7          	jalr	-732(ra) # 80000cec <release>
  return pid;
    80001fd0:	74a2                	ld	s1,40(sp)
    80001fd2:	69e2                	ld	s3,24(sp)
    80001fd4:	6a42                	ld	s4,16(sp)
}
    80001fd6:	854a                	mv	a0,s2
    80001fd8:	70e2                	ld	ra,56(sp)
    80001fda:	7442                	ld	s0,48(sp)
    80001fdc:	7902                	ld	s2,32(sp)
    80001fde:	6aa2                	ld	s5,8(sp)
    80001fe0:	6121                	addi	sp,sp,64
    80001fe2:	8082                	ret
    return -1;
    80001fe4:	597d                	li	s2,-1
    80001fe6:	bfc5                	j	80001fd6 <fork+0x13a>

0000000080001fe8 <get_time_slice>:
{
    80001fe8:	1141                	addi	sp,sp,-16
    80001fea:	e422                	sd	s0,8(sp)
    80001fec:	0800                	addi	s0,sp,16
  switch (priority)
    80001fee:	4709                	li	a4,2
    80001ff0:	00e50d63          	beq	a0,a4,8000200a <get_time_slice+0x22>
    80001ff4:	87aa                	mv	a5,a0
    80001ff6:	470d                	li	a4,3
    return 16;
    80001ff8:	4541                	li	a0,16
  switch (priority)
    80001ffa:	00e78963          	beq	a5,a4,8000200c <get_time_slice+0x24>
    80001ffe:	4705                	li	a4,1
    80002000:	4511                	li	a0,4
    80002002:	00e78563          	beq	a5,a4,8000200c <get_time_slice+0x24>
    return 1;
    80002006:	4505                	li	a0,1
    80002008:	a011                	j	8000200c <get_time_slice+0x24>
    return 8;
    8000200a:	4521                	li	a0,8
}
    8000200c:	6422                	ld	s0,8(sp)
    8000200e:	0141                	addi	sp,sp,16
    80002010:	8082                	ret

0000000080002012 <scheduler_mlfq>:
{
    80002012:	711d                	addi	sp,sp,-96
    80002014:	ec86                	sd	ra,88(sp)
    80002016:	e8a2                	sd	s0,80(sp)
    80002018:	e4a6                	sd	s1,72(sp)
    8000201a:	e0ca                	sd	s2,64(sp)
    8000201c:	fc4e                	sd	s3,56(sp)
    8000201e:	f852                	sd	s4,48(sp)
    80002020:	f456                	sd	s5,40(sp)
    80002022:	f05a                	sd	s6,32(sp)
    80002024:	ec5e                	sd	s7,24(sp)
    80002026:	e862                	sd	s8,16(sp)
    80002028:	e466                	sd	s9,8(sp)
    8000202a:	e06a                	sd	s10,0(sp)
    8000202c:	1080                	addi	s0,sp,96
    8000202e:	8792                	mv	a5,tp
  int id = r_tp();
    80002030:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002032:	00779c93          	slli	s9,a5,0x7
    80002036:	00011717          	auipc	a4,0x11
    8000203a:	62a70713          	addi	a4,a4,1578 # 80013660 <pid_lock>
    8000203e:	9766                	add	a4,a4,s9
    80002040:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &selected_proc->context);
    80002044:	00011717          	auipc	a4,0x11
    80002048:	65470713          	addi	a4,a4,1620 # 80013698 <cpus+0x8>
    8000204c:	9cba                	add	s9,s9,a4
    for (p = proc; p < &proc[NPROC]; p++)
    8000204e:	0001f917          	auipc	s2,0x1f
    80002052:	65290913          	addi	s2,s2,1618 # 800216a0 <tickslock>
          p->arrival_time = ticks;
    80002056:	00009a17          	auipc	s4,0x9
    8000205a:	39ea0a13          	addi	s4,s4,926 # 8000b3f4 <ticks>
    c->proc = selected_proc;
    8000205e:	079e                	slli	a5,a5,0x7
    80002060:	00011c17          	auipc	s8,0x11
    80002064:	600c0c13          	addi	s8,s8,1536 # 80013660 <pid_lock>
    80002068:	9c3e                	add	s8,s8,a5
    8000206a:	aa11                	j	8000217e <scheduler_mlfq+0x16c>
      for (p = proc; p < &proc[NPROC]; p++)
    8000206c:	00012497          	auipc	s1,0x12
    80002070:	23448493          	addi	s1,s1,564 # 800142a0 <proc>
        if (p->state == RUNNABLE)
    80002074:	4d0d                	li	s10,3
    80002076:	a029                	j	80002080 <scheduler_mlfq+0x6e>
      for (p = proc; p < &proc[NPROC]; p++)
    80002078:	35048493          	addi	s1,s1,848
    8000207c:	03248763          	beq	s1,s2,800020aa <scheduler_mlfq+0x98>
        if (p->state == RUNNABLE)
    80002080:	4c9c                	lw	a5,24(s1)
    80002082:	ffa79be3          	bne	a5,s10,80002078 <scheduler_mlfq+0x66>
          acquire(&p->lock);
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	bb0080e7          	jalr	-1104(ra) # 80000c38 <acquire>
          p->arrival_time = ticks;
    80002090:	000a6783          	lwu	a5,0(s4)
    80002094:	e4fc                	sd	a5,200(s1)
          p->ticks=0;
    80002096:	0e04a023          	sw	zero,224(s1)
          p->priority = 0;
    8000209a:	0c04ac23          	sw	zero,216(s1)
          release(&p->lock);
    8000209e:	8526                	mv	a0,s1
    800020a0:	fffff097          	auipc	ra,0xfffff
    800020a4:	c4c080e7          	jalr	-948(ra) # 80000cec <release>
    800020a8:	bfc1                	j	80002078 <scheduler_mlfq+0x66>
      boost_ticks = 0;
    800020aa:	00009797          	auipc	a5,0x9
    800020ae:	3407a323          	sw	zero,838(a5) # 8000b3f0 <boost_ticks>
    800020b2:	a8c5                	j	800021a2 <scheduler_mlfq+0x190>
        if (selected_proc == 0)
    800020b4:	cc89                	beqz	s1,800020ce <scheduler_mlfq+0xbc>
        else if (p->priority < min)
    800020b6:	0d87a703          	lw	a4,216(a5)
    800020ba:	04d74b63          	blt	a4,a3,80002110 <scheduler_mlfq+0xfe>
        else if (p->priority == min && p->arrival_time < selected_proc->arrival_time)
    800020be:	04d71b63          	bne	a4,a3,80002114 <scheduler_mlfq+0x102>
    800020c2:	67f0                	ld	a2,200(a5)
    800020c4:	64f8                	ld	a4,200(s1)
    800020c6:	04e67763          	bgeu	a2,a4,80002114 <scheduler_mlfq+0x102>
          selected_proc = p;
    800020ca:	84be                	mv	s1,a5
    800020cc:	a0a1                	j	80002114 <scheduler_mlfq+0x102>
          min = selected_proc->priority;
    800020ce:	0d87a683          	lw	a3,216(a5)
          selected_proc = p;
    800020d2:	84be                	mv	s1,a5
    800020d4:	a081                	j	80002114 <scheduler_mlfq+0x102>
      release(&selected_proc->lock);
    800020d6:	8526                	mv	a0,s1
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	c14080e7          	jalr	-1004(ra) # 80000cec <release>
      continue;
    800020e0:	a879                	j	8000217e <scheduler_mlfq+0x16c>
      if (selected_proc->ticks >= time_slice)
    800020e2:	0e04ab03          	lw	s6,224(s1)
    int time_slice = get_time_slice(selected_proc->priority);
    800020e6:	8556                	mv	a0,s5
    800020e8:	00000097          	auipc	ra,0x0
    800020ec:	f00080e7          	jalr	-256(ra) # 80001fe8 <get_time_slice>
      if (selected_proc->ticks >= time_slice)
    800020f0:	06ab4963          	blt	s6,a0,80002162 <scheduler_mlfq+0x150>
        if (selected_proc->priority < MAX_PRIORITY)
    800020f4:	0d84a783          	lw	a5,216(s1)
    800020f8:	4709                	li	a4,2
    800020fa:	00f74863          	blt	a4,a5,8000210a <scheduler_mlfq+0xf8>
          selected_proc->priority++;
    800020fe:	2785                	addiw	a5,a5,1
    80002100:	0cf4ac23          	sw	a5,216(s1)
          selected_proc->arrival_time=ticks;
    80002104:	000a6783          	lwu	a5,0(s4)
    80002108:	e4fc                	sd	a5,200(s1)
        selected_proc->ticks = 0;
    8000210a:	0e04a023          	sw	zero,224(s1)
    8000210e:	a891                	j	80002162 <scheduler_mlfq+0x150>
          min = selected_proc->priority;
    80002110:	86ba                	mv	a3,a4
          selected_proc = p;
    80002112:	84be                	mv	s1,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002114:	35078793          	addi	a5,a5,848
    80002118:	01278a63          	beq	a5,s2,8000212c <scheduler_mlfq+0x11a>
      if (p->state == RUNNABLE)
    8000211c:	4f98                	lw	a4,24(a5)
    8000211e:	f9370be3          	beq	a4,s3,800020b4 <scheduler_mlfq+0xa2>
    for (p = proc; p < &proc[NPROC]; p++)
    80002122:	35078793          	addi	a5,a5,848
    80002126:	ff279be3          	bne	a5,s2,8000211c <scheduler_mlfq+0x10a>
    if (!selected_proc)
    8000212a:	c0b5                	beqz	s1,8000218e <scheduler_mlfq+0x17c>
    acquire(&selected_proc->lock);
    8000212c:	89a6                	mv	s3,s1
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b08080e7          	jalr	-1272(ra) # 80000c38 <acquire>
    if (selected_proc->state != RUNNABLE)
    80002138:	4c98                	lw	a4,24(s1)
    8000213a:	478d                	li	a5,3
    8000213c:	f8f71de3          	bne	a4,a5,800020d6 <scheduler_mlfq+0xc4>
    selected_proc->state = RUNNING;
    80002140:	4791                	li	a5,4
    80002142:	cc9c                	sw	a5,24(s1)
    c->proc = selected_proc;
    80002144:	029c3823          	sd	s1,48(s8)
    int time_slice = get_time_slice(selected_proc->priority);
    80002148:	0d84aa83          	lw	s5,216(s1)
    swtch(&c->context, &selected_proc->context);
    8000214c:	23848593          	addi	a1,s1,568
    80002150:	8566                	mv	a0,s9
    80002152:	00001097          	auipc	ra,0x1
    80002156:	ad0080e7          	jalr	-1328(ra) # 80002c22 <swtch>
    if (selected_proc->state == RUNNABLE)
    8000215a:	4c98                	lw	a4,24(s1)
    8000215c:	478d                	li	a5,3
    8000215e:	f8f702e3          	beq	a4,a5,800020e2 <scheduler_mlfq+0xd0>
    c->proc = 0;
    80002162:	020c3823          	sd	zero,48(s8)
    release(&selected_proc->lock);
    80002166:	854e                	mv	a0,s3
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b84080e7          	jalr	-1148(ra) # 80000cec <release>
    boost_ticks++;
    80002170:	00009717          	auipc	a4,0x9
    80002174:	28070713          	addi	a4,a4,640 # 8000b3f0 <boost_ticks>
    80002178:	431c                	lw	a5,0(a4)
    8000217a:	2785                	addiw	a5,a5,1
    8000217c:	c31c                	sw	a5,0(a4)
    if (boost_ticks >= BOOST_INTERVAL)
    8000217e:	00009b97          	auipc	s7,0x9
    80002182:	272b8b93          	addi	s7,s7,626 # 8000b3f0 <boost_ticks>
    80002186:	02f00b13          	li	s6,47
    int min=3;
    8000218a:	498d                	li	s3,3
    struct proc *selected_proc = 0;
    8000218c:	4a81                	li	s5,0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000218e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002192:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002196:	10079073          	csrw	sstatus,a5
    if (boost_ticks >= BOOST_INTERVAL)
    8000219a:	000ba783          	lw	a5,0(s7)
    8000219e:	ecfb47e3          	blt	s6,a5,8000206c <scheduler_mlfq+0x5a>
    int min=3;
    800021a2:	86ce                	mv	a3,s3
    struct proc *selected_proc = 0;
    800021a4:	84d6                	mv	s1,s5
    for (p = proc; p < &proc[NPROC]; p++)
    800021a6:	00012797          	auipc	a5,0x12
    800021aa:	0fa78793          	addi	a5,a5,250 # 800142a0 <proc>
    800021ae:	b7bd                	j	8000211c <scheduler_mlfq+0x10a>

00000000800021b0 <scheduler_rr>:
{
    800021b0:	7139                	addi	sp,sp,-64
    800021b2:	fc06                	sd	ra,56(sp)
    800021b4:	f822                	sd	s0,48(sp)
    800021b6:	f426                	sd	s1,40(sp)
    800021b8:	f04a                	sd	s2,32(sp)
    800021ba:	ec4e                	sd	s3,24(sp)
    800021bc:	e852                	sd	s4,16(sp)
    800021be:	e456                	sd	s5,8(sp)
    800021c0:	e05a                	sd	s6,0(sp)
    800021c2:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    800021c4:	8792                	mv	a5,tp
  int id = r_tp();
    800021c6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021c8:	00779a93          	slli	s5,a5,0x7
    800021cc:	00011717          	auipc	a4,0x11
    800021d0:	49470713          	addi	a4,a4,1172 # 80013660 <pid_lock>
    800021d4:	9756                	add	a4,a4,s5
    800021d6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021da:	00011717          	auipc	a4,0x11
    800021de:	4be70713          	addi	a4,a4,1214 # 80013698 <cpus+0x8>
    800021e2:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800021e4:	498d                	li	s3,3
        p->state = RUNNING;
    800021e6:	4b11                	li	s6,4
        c->proc = p;
    800021e8:	079e                	slli	a5,a5,0x7
    800021ea:	00011a17          	auipc	s4,0x11
    800021ee:	476a0a13          	addi	s4,s4,1142 # 80013660 <pid_lock>
    800021f2:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021f4:	0001f917          	auipc	s2,0x1f
    800021f8:	4ac90913          	addi	s2,s2,1196 # 800216a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002200:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002204:	10079073          	csrw	sstatus,a5
    80002208:	00012497          	auipc	s1,0x12
    8000220c:	09848493          	addi	s1,s1,152 # 800142a0 <proc>
    80002210:	a811                	j	80002224 <scheduler_rr+0x74>
      release(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	ad8080e7          	jalr	-1320(ra) # 80000cec <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000221c:	35048493          	addi	s1,s1,848
    80002220:	fd248ee3          	beq	s1,s2,800021fc <scheduler_rr+0x4c>
      acquire(&p->lock);
    80002224:	8526                	mv	a0,s1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a12080e7          	jalr	-1518(ra) # 80000c38 <acquire>
      if (p->state == RUNNABLE)
    8000222e:	4c9c                	lw	a5,24(s1)
    80002230:	ff3791e3          	bne	a5,s3,80002212 <scheduler_rr+0x62>
        p->state = RUNNING;
    80002234:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002238:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000223c:	23848593          	addi	a1,s1,568
    80002240:	8556                	mv	a0,s5
    80002242:	00001097          	auipc	ra,0x1
    80002246:	9e0080e7          	jalr	-1568(ra) # 80002c22 <swtch>
        c->proc = 0;
    8000224a:	020a3823          	sd	zero,48(s4)
    8000224e:	b7d1                	j	80002212 <scheduler_rr+0x62>

0000000080002250 <scheduler_lottery>:
{
    80002250:	715d                	addi	sp,sp,-80
    80002252:	e486                	sd	ra,72(sp)
    80002254:	e0a2                	sd	s0,64(sp)
    80002256:	fc26                	sd	s1,56(sp)
    80002258:	f84a                	sd	s2,48(sp)
    8000225a:	f44e                	sd	s3,40(sp)
    8000225c:	f052                	sd	s4,32(sp)
    8000225e:	ec56                	sd	s5,24(sp)
    80002260:	e85a                	sd	s6,16(sp)
    80002262:	e45e                	sd	s7,8(sp)
    80002264:	e062                	sd	s8,0(sp)
    80002266:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002268:	8792                	mv	a5,tp
  int id = r_tp();
    8000226a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000226c:	00779693          	slli	a3,a5,0x7
    80002270:	00011717          	auipc	a4,0x11
    80002274:	3f070713          	addi	a4,a4,1008 # 80013660 <pid_lock>
    80002278:	9736                	add	a4,a4,a3
    8000227a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &selected_proc->context);
    8000227e:	00011717          	auipc	a4,0x11
    80002282:	41a70713          	addi	a4,a4,1050 # 80013698 <cpus+0x8>
    80002286:	00e68c33          	add	s8,a3,a4
    total_tickets = 0;
    8000228a:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    8000228c:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	0001f917          	auipc	s2,0x1f
    80002292:	41290913          	addi	s2,s2,1042 # 800216a0 <tickslock>
        c->proc = selected_proc;
    80002296:	00011b17          	auipc	s6,0x11
    8000229a:	3cab0b13          	addi	s6,s6,970 # 80013660 <pid_lock>
    8000229e:	9b36                	add	s6,s6,a3
    800022a0:	a80d                	j	800022d2 <scheduler_lottery+0x82>
      release(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	a48080e7          	jalr	-1464(ra) # 80000cec <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022ac:	35048493          	addi	s1,s1,848
    800022b0:	01248f63          	beq	s1,s2,800022ce <scheduler_lottery+0x7e>
      acquire(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	982080e7          	jalr	-1662(ra) # 80000c38 <acquire>
      if (p->state == RUNNABLE)
    800022be:	4c9c                	lw	a5,24(s1)
    800022c0:	ff3791e3          	bne	a5,s3,800022a2 <scheduler_lottery+0x52>
        total_tickets += p->tickets;
    800022c4:	0c04a783          	lw	a5,192(s1)
    800022c8:	01778bbb          	addw	s7,a5,s7
    800022cc:	bfd9                	j	800022a2 <scheduler_lottery+0x52>
    if (total_tickets == 0)
    800022ce:	000b9e63          	bnez	s7,800022ea <scheduler_lottery+0x9a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022da:	10079073          	csrw	sstatus,a5
    total_tickets = 0;
    800022de:	8bd6                	mv	s7,s5
    for (p = proc; p < &proc[NPROC]; p++)
    800022e0:	00012497          	auipc	s1,0x12
    800022e4:	fc048493          	addi	s1,s1,-64 # 800142a0 <proc>
    800022e8:	b7f1                	j	800022b4 <scheduler_lottery+0x64>
    int winning_ticket = rand() % total_tickets;
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	672080e7          	jalr	1650(ra) # 8000195c <rand>
    800022f2:	03757bb3          	remu	s7,a0,s7
    800022f6:	2b81                	sext.w	s7,s7
    int current_ticket = 0;
    800022f8:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    800022fa:	00012497          	auipc	s1,0x12
    800022fe:	fa648493          	addi	s1,s1,-90 # 800142a0 <proc>
    80002302:	a811                	j	80002316 <scheduler_lottery+0xc6>
      release(&p->lock);
    80002304:	8526                	mv	a0,s1
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	9e6080e7          	jalr	-1562(ra) # 80000cec <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000230e:	35048493          	addi	s1,s1,848
    80002312:	fd2480e3          	beq	s1,s2,800022d2 <scheduler_lottery+0x82>
      acquire(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	920080e7          	jalr	-1760(ra) # 80000c38 <acquire>
      if (p->state == RUNNABLE)
    80002320:	4c9c                	lw	a5,24(s1)
    80002322:	ff3791e3          	bne	a5,s3,80002304 <scheduler_lottery+0xb4>
        current_ticket += p->tickets;
    80002326:	0c04a783          	lw	a5,192(s1)
    8000232a:	01478a3b          	addw	s4,a5,s4
        if (current_ticket > winning_ticket)
    8000232e:	fd4bdbe3          	bge	s7,s4,80002304 <scheduler_lottery+0xb4>
          release(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	9b8080e7          	jalr	-1608(ra) # 80000cec <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000233c:	00012a17          	auipc	s4,0x12
    80002340:	f64a0a13          	addi	s4,s4,-156 # 800142a0 <proc>
    80002344:	a811                	j	80002358 <scheduler_lottery+0x108>
          release(&p->lock);
    80002346:	8552                	mv	a0,s4
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	9a4080e7          	jalr	-1628(ra) # 80000cec <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002350:	350a0a13          	addi	s4,s4,848
    80002354:	032a0a63          	beq	s4,s2,80002388 <scheduler_lottery+0x138>
        if (p != selected_proc)
    80002358:	fe9a0ce3          	beq	s4,s1,80002350 <scheduler_lottery+0x100>
          acquire(&p->lock);
    8000235c:	8552                	mv	a0,s4
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	8da080e7          	jalr	-1830(ra) # 80000c38 <acquire>
          if (p->state == RUNNABLE && p->tickets == selected_proc->tickets && p->arrival_time < selected_proc->arrival_time)
    80002366:	018a2783          	lw	a5,24(s4)
    8000236a:	fd379ee3          	bne	a5,s3,80002346 <scheduler_lottery+0xf6>
    8000236e:	0c0a2703          	lw	a4,192(s4)
    80002372:	0c04a783          	lw	a5,192(s1)
    80002376:	fcf718e3          	bne	a4,a5,80002346 <scheduler_lottery+0xf6>
    8000237a:	0c8a3703          	ld	a4,200(s4)
    8000237e:	64fc                	ld	a5,200(s1)
    80002380:	fcf773e3          	bgeu	a4,a5,80002346 <scheduler_lottery+0xf6>
            selected_proc = p;
    80002384:	84d2                	mv	s1,s4
    80002386:	b7c1                	j	80002346 <scheduler_lottery+0xf6>
      acquire(&selected_proc->lock);
    80002388:	8a26                	mv	s4,s1
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8ac080e7          	jalr	-1876(ra) # 80000c38 <acquire>
      if (selected_proc->state == RUNNABLE)
    80002394:	4c9c                	lw	a5,24(s1)
    80002396:	01378863          	beq	a5,s3,800023a6 <scheduler_lottery+0x156>
      release(&selected_proc->lock);
    8000239a:	8552                	mv	a0,s4
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	950080e7          	jalr	-1712(ra) # 80000cec <release>
    800023a4:	b73d                	j	800022d2 <scheduler_lottery+0x82>
        selected_proc->state = RUNNING;
    800023a6:	4791                	li	a5,4
    800023a8:	cc9c                	sw	a5,24(s1)
        c->proc = selected_proc;
    800023aa:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &selected_proc->context);
    800023ae:	23848593          	addi	a1,s1,568
    800023b2:	8562                	mv	a0,s8
    800023b4:	00001097          	auipc	ra,0x1
    800023b8:	86e080e7          	jalr	-1938(ra) # 80002c22 <swtch>
        c->proc = 0;
    800023bc:	020b3823          	sd	zero,48(s6)
    800023c0:	bfe9                	j	8000239a <scheduler_lottery+0x14a>

00000000800023c2 <scheduler>:
{
    800023c2:	1141                	addi	sp,sp,-16
    800023c4:	e406                	sd	ra,8(sp)
    800023c6:	e022                	sd	s0,0(sp)
    800023c8:	0800                	addi	s0,sp,16
      scheduler_rr();
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	de6080e7          	jalr	-538(ra) # 800021b0 <scheduler_rr>

00000000800023d2 <sched>:
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	69a080e7          	jalr	1690(ra) # 80001a7a <myproc>
    800023e8:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7d4080e7          	jalr	2004(ra) # 80000bbe <holding>
    800023f2:	c93d                	beqz	a0,80002468 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023f4:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800023f6:	2781                	sext.w	a5,a5
    800023f8:	079e                	slli	a5,a5,0x7
    800023fa:	00011717          	auipc	a4,0x11
    800023fe:	26670713          	addi	a4,a4,614 # 80013660 <pid_lock>
    80002402:	97ba                	add	a5,a5,a4
    80002404:	0a87a703          	lw	a4,168(a5)
    80002408:	4785                	li	a5,1
    8000240a:	06f71763          	bne	a4,a5,80002478 <sched+0xa6>
  if (p->state == RUNNING)
    8000240e:	4c98                	lw	a4,24(s1)
    80002410:	4791                	li	a5,4
    80002412:	06f70b63          	beq	a4,a5,80002488 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002416:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000241a:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000241c:	efb5                	bnez	a5,80002498 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000241e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002420:	00011917          	auipc	s2,0x11
    80002424:	24090913          	addi	s2,s2,576 # 80013660 <pid_lock>
    80002428:	2781                	sext.w	a5,a5
    8000242a:	079e                	slli	a5,a5,0x7
    8000242c:	97ca                	add	a5,a5,s2
    8000242e:	0ac7a983          	lw	s3,172(a5)
    80002432:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002434:	2781                	sext.w	a5,a5
    80002436:	079e                	slli	a5,a5,0x7
    80002438:	00011597          	auipc	a1,0x11
    8000243c:	26058593          	addi	a1,a1,608 # 80013698 <cpus+0x8>
    80002440:	95be                	add	a1,a1,a5
    80002442:	23848513          	addi	a0,s1,568
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	7dc080e7          	jalr	2012(ra) # 80002c22 <swtch>
    8000244e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002450:	2781                	sext.w	a5,a5
    80002452:	079e                	slli	a5,a5,0x7
    80002454:	993e                	add	s2,s2,a5
    80002456:	0b392623          	sw	s3,172(s2)
}
    8000245a:	70a2                	ld	ra,40(sp)
    8000245c:	7402                	ld	s0,32(sp)
    8000245e:	64e2                	ld	s1,24(sp)
    80002460:	6942                	ld	s2,16(sp)
    80002462:	69a2                	ld	s3,8(sp)
    80002464:	6145                	addi	sp,sp,48
    80002466:	8082                	ret
    panic("sched p->lock");
    80002468:	00006517          	auipc	a0,0x6
    8000246c:	d9050513          	addi	a0,a0,-624 # 800081f8 <etext+0x1f8>
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	0f0080e7          	jalr	240(ra) # 80000560 <panic>
    panic("sched locks");
    80002478:	00006517          	auipc	a0,0x6
    8000247c:	d9050513          	addi	a0,a0,-624 # 80008208 <etext+0x208>
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	0e0080e7          	jalr	224(ra) # 80000560 <panic>
    panic("sched running");
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	d9050513          	addi	a0,a0,-624 # 80008218 <etext+0x218>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	0d0080e7          	jalr	208(ra) # 80000560 <panic>
    panic("sched interruptible");
    80002498:	00006517          	auipc	a0,0x6
    8000249c:	d9050513          	addi	a0,a0,-624 # 80008228 <etext+0x228>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	0c0080e7          	jalr	192(ra) # 80000560 <panic>

00000000800024a8 <yield>:
{
    800024a8:	1101                	addi	sp,sp,-32
    800024aa:	ec06                	sd	ra,24(sp)
    800024ac:	e822                	sd	s0,16(sp)
    800024ae:	e426                	sd	s1,8(sp)
    800024b0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	5c8080e7          	jalr	1480(ra) # 80001a7a <myproc>
    800024ba:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	77c080e7          	jalr	1916(ra) # 80000c38 <acquire>
  p->state = RUNNABLE;
    800024c4:	478d                	li	a5,3
    800024c6:	cc9c                	sw	a5,24(s1)
  sched();
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	f0a080e7          	jalr	-246(ra) # 800023d2 <sched>
  release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	81a080e7          	jalr	-2022(ra) # 80000cec <release>
}
    800024da:	60e2                	ld	ra,24(sp)
    800024dc:	6442                	ld	s0,16(sp)
    800024de:	64a2                	ld	s1,8(sp)
    800024e0:	6105                	addi	sp,sp,32
    800024e2:	8082                	ret

00000000800024e4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024e4:	7179                	addi	sp,sp,-48
    800024e6:	f406                	sd	ra,40(sp)
    800024e8:	f022                	sd	s0,32(sp)
    800024ea:	ec26                	sd	s1,24(sp)
    800024ec:	e84a                	sd	s2,16(sp)
    800024ee:	e44e                	sd	s3,8(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	89aa                	mv	s3,a0
    800024f4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	584080e7          	jalr	1412(ra) # 80001a7a <myproc>
    800024fe:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	738080e7          	jalr	1848(ra) # 80000c38 <acquire>
  release(lk);
    80002508:	854a                	mv	a0,s2
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	7e2080e7          	jalr	2018(ra) # 80000cec <release>

  // Go to sleep.
  p->chan = chan;
    80002512:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002516:	4789                	li	a5,2
    80002518:	cc9c                	sw	a5,24(s1)

  sched();
    8000251a:	00000097          	auipc	ra,0x0
    8000251e:	eb8080e7          	jalr	-328(ra) # 800023d2 <sched>

  // Tidy up.
  p->chan = 0;
    80002522:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	7c4080e7          	jalr	1988(ra) # 80000cec <release>
  acquire(lk);
    80002530:	854a                	mv	a0,s2
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	706080e7          	jalr	1798(ra) # 80000c38 <acquire>
}
    8000253a:	70a2                	ld	ra,40(sp)
    8000253c:	7402                	ld	s0,32(sp)
    8000253e:	64e2                	ld	s1,24(sp)
    80002540:	6942                	ld	s2,16(sp)
    80002542:	69a2                	ld	s3,8(sp)
    80002544:	6145                	addi	sp,sp,48
    80002546:	8082                	ret

0000000080002548 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002548:	7139                	addi	sp,sp,-64
    8000254a:	fc06                	sd	ra,56(sp)
    8000254c:	f822                	sd	s0,48(sp)
    8000254e:	f426                	sd	s1,40(sp)
    80002550:	f04a                	sd	s2,32(sp)
    80002552:	ec4e                	sd	s3,24(sp)
    80002554:	e852                	sd	s4,16(sp)
    80002556:	e456                	sd	s5,8(sp)
    80002558:	0080                	addi	s0,sp,64
    8000255a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000255c:	00012497          	auipc	s1,0x12
    80002560:	d4448493          	addi	s1,s1,-700 # 800142a0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002564:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002566:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002568:	0001f917          	auipc	s2,0x1f
    8000256c:	13890913          	addi	s2,s2,312 # 800216a0 <tickslock>
    80002570:	a811                	j	80002584 <wakeup+0x3c>
      }
      release(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	778080e7          	jalr	1912(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000257c:	35048493          	addi	s1,s1,848
    80002580:	03248663          	beq	s1,s2,800025ac <wakeup+0x64>
    if (p != myproc())
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	4f6080e7          	jalr	1270(ra) # 80001a7a <myproc>
    8000258c:	fea488e3          	beq	s1,a0,8000257c <wakeup+0x34>
      acquire(&p->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	6a6080e7          	jalr	1702(ra) # 80000c38 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000259a:	4c9c                	lw	a5,24(s1)
    8000259c:	fd379be3          	bne	a5,s3,80002572 <wakeup+0x2a>
    800025a0:	709c                	ld	a5,32(s1)
    800025a2:	fd4798e3          	bne	a5,s4,80002572 <wakeup+0x2a>
        p->state = RUNNABLE;
    800025a6:	0154ac23          	sw	s5,24(s1)
    800025aa:	b7e1                	j	80002572 <wakeup+0x2a>
    }
  }
}
    800025ac:	70e2                	ld	ra,56(sp)
    800025ae:	7442                	ld	s0,48(sp)
    800025b0:	74a2                	ld	s1,40(sp)
    800025b2:	7902                	ld	s2,32(sp)
    800025b4:	69e2                	ld	s3,24(sp)
    800025b6:	6a42                	ld	s4,16(sp)
    800025b8:	6aa2                	ld	s5,8(sp)
    800025ba:	6121                	addi	sp,sp,64
    800025bc:	8082                	ret

00000000800025be <reparent>:
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025d0:	00012497          	auipc	s1,0x12
    800025d4:	cd048493          	addi	s1,s1,-816 # 800142a0 <proc>
      pp->parent = initproc;
    800025d8:	00009a17          	auipc	s4,0x9
    800025dc:	e10a0a13          	addi	s4,s4,-496 # 8000b3e8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e0:	0001f997          	auipc	s3,0x1f
    800025e4:	0c098993          	addi	s3,s3,192 # 800216a0 <tickslock>
    800025e8:	a029                	j	800025f2 <reparent+0x34>
    800025ea:	35048493          	addi	s1,s1,848
    800025ee:	01348d63          	beq	s1,s3,80002608 <reparent+0x4a>
    if (pp->parent == p)
    800025f2:	7c9c                	ld	a5,56(s1)
    800025f4:	ff279be3          	bne	a5,s2,800025ea <reparent+0x2c>
      pp->parent = initproc;
    800025f8:	000a3503          	ld	a0,0(s4)
    800025fc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	f4a080e7          	jalr	-182(ra) # 80002548 <wakeup>
    80002606:	b7d5                	j	800025ea <reparent+0x2c>
}
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	addi	sp,sp,48
    80002616:	8082                	ret

0000000080002618 <exit>:
{
    80002618:	7179                	addi	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	e052                	sd	s4,0(sp)
    80002626:	1800                	addi	s0,sp,48
    80002628:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	450080e7          	jalr	1104(ra) # 80001a7a <myproc>
    80002632:	89aa                	mv	s3,a0
  if (p == initproc)
    80002634:	00009797          	auipc	a5,0x9
    80002638:	db47b783          	ld	a5,-588(a5) # 8000b3e8 <initproc>
    8000263c:	2a850493          	addi	s1,a0,680
    80002640:	32850913          	addi	s2,a0,808
    80002644:	02a79363          	bne	a5,a0,8000266a <exit+0x52>
    panic("init exiting");
    80002648:	00006517          	auipc	a0,0x6
    8000264c:	bf850513          	addi	a0,a0,-1032 # 80008240 <etext+0x240>
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	f10080e7          	jalr	-240(ra) # 80000560 <panic>
      fileclose(f);
    80002658:	00002097          	auipc	ra,0x2
    8000265c:	732080e7          	jalr	1842(ra) # 80004d8a <fileclose>
      p->ofile[fd] = 0;
    80002660:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002664:	04a1                	addi	s1,s1,8
    80002666:	01248563          	beq	s1,s2,80002670 <exit+0x58>
    if (p->ofile[fd])
    8000266a:	6088                	ld	a0,0(s1)
    8000266c:	f575                	bnez	a0,80002658 <exit+0x40>
    8000266e:	bfdd                	j	80002664 <exit+0x4c>
  begin_op();
    80002670:	00002097          	auipc	ra,0x2
    80002674:	250080e7          	jalr	592(ra) # 800048c0 <begin_op>
  iput(p->cwd);
    80002678:	3289b503          	ld	a0,808(s3)
    8000267c:	00002097          	auipc	ra,0x2
    80002680:	a34080e7          	jalr	-1484(ra) # 800040b0 <iput>
  end_op();
    80002684:	00002097          	auipc	ra,0x2
    80002688:	2b6080e7          	jalr	694(ra) # 8000493a <end_op>
  p->cwd = 0;
    8000268c:	3209b423          	sd	zero,808(s3)
  acquire(&wait_lock);
    80002690:	00011497          	auipc	s1,0x11
    80002694:	fe848493          	addi	s1,s1,-24 # 80013678 <wait_lock>
    80002698:	8526                	mv	a0,s1
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	59e080e7          	jalr	1438(ra) # 80000c38 <acquire>
  reparent(p);
    800026a2:	854e                	mv	a0,s3
    800026a4:	00000097          	auipc	ra,0x0
    800026a8:	f1a080e7          	jalr	-230(ra) # 800025be <reparent>
  wakeup(p->parent);
    800026ac:	0389b503          	ld	a0,56(s3)
    800026b0:	00000097          	auipc	ra,0x0
    800026b4:	e98080e7          	jalr	-360(ra) # 80002548 <wakeup>
  acquire(&p->lock);
    800026b8:	854e                	mv	a0,s3
    800026ba:	ffffe097          	auipc	ra,0xffffe
    800026be:	57e080e7          	jalr	1406(ra) # 80000c38 <acquire>
  p->xstate = status;
    800026c2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026c6:	4795                	li	a5,5
    800026c8:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800026cc:	00009797          	auipc	a5,0x9
    800026d0:	d287a783          	lw	a5,-728(a5) # 8000b3f4 <ticks>
    800026d4:	34f9a423          	sw	a5,840(s3)
  release(&wait_lock);
    800026d8:	8526                	mv	a0,s1
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	612080e7          	jalr	1554(ra) # 80000cec <release>
  sched();
    800026e2:	00000097          	auipc	ra,0x0
    800026e6:	cf0080e7          	jalr	-784(ra) # 800023d2 <sched>
  panic("zombie exit");
    800026ea:	00006517          	auipc	a0,0x6
    800026ee:	b6650513          	addi	a0,a0,-1178 # 80008250 <etext+0x250>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	e6e080e7          	jalr	-402(ra) # 80000560 <panic>

00000000800026fa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026fa:	7179                	addi	sp,sp,-48
    800026fc:	f406                	sd	ra,40(sp)
    800026fe:	f022                	sd	s0,32(sp)
    80002700:	ec26                	sd	s1,24(sp)
    80002702:	e84a                	sd	s2,16(sp)
    80002704:	e44e                	sd	s3,8(sp)
    80002706:	1800                	addi	s0,sp,48
    80002708:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000270a:	00012497          	auipc	s1,0x12
    8000270e:	b9648493          	addi	s1,s1,-1130 # 800142a0 <proc>
    80002712:	0001f997          	auipc	s3,0x1f
    80002716:	f8e98993          	addi	s3,s3,-114 # 800216a0 <tickslock>
  {
    acquire(&p->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	51c080e7          	jalr	1308(ra) # 80000c38 <acquire>
    if (p->pid == pid)
    80002724:	589c                	lw	a5,48(s1)
    80002726:	01278d63          	beq	a5,s2,80002740 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000272a:	8526                	mv	a0,s1
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	5c0080e7          	jalr	1472(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002734:	35048493          	addi	s1,s1,848
    80002738:	ff3491e3          	bne	s1,s3,8000271a <kill+0x20>
  }
  return -1;
    8000273c:	557d                	li	a0,-1
    8000273e:	a829                	j	80002758 <kill+0x5e>
      p->killed = 1;
    80002740:	4785                	li	a5,1
    80002742:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002744:	4c98                	lw	a4,24(s1)
    80002746:	4789                	li	a5,2
    80002748:	00f70f63          	beq	a4,a5,80002766 <kill+0x6c>
      release(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	59e080e7          	jalr	1438(ra) # 80000cec <release>
      return 0;
    80002756:	4501                	li	a0,0
}
    80002758:	70a2                	ld	ra,40(sp)
    8000275a:	7402                	ld	s0,32(sp)
    8000275c:	64e2                	ld	s1,24(sp)
    8000275e:	6942                	ld	s2,16(sp)
    80002760:	69a2                	ld	s3,8(sp)
    80002762:	6145                	addi	sp,sp,48
    80002764:	8082                	ret
        p->state = RUNNABLE;
    80002766:	478d                	li	a5,3
    80002768:	cc9c                	sw	a5,24(s1)
    8000276a:	b7cd                	j	8000274c <kill+0x52>

000000008000276c <setkilled>:

void setkilled(struct proc *p)
{
    8000276c:	1101                	addi	sp,sp,-32
    8000276e:	ec06                	sd	ra,24(sp)
    80002770:	e822                	sd	s0,16(sp)
    80002772:	e426                	sd	s1,8(sp)
    80002774:	1000                	addi	s0,sp,32
    80002776:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	4c0080e7          	jalr	1216(ra) # 80000c38 <acquire>
  p->killed = 1;
    80002780:	4785                	li	a5,1
    80002782:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	566080e7          	jalr	1382(ra) # 80000cec <release>
}
    8000278e:	60e2                	ld	ra,24(sp)
    80002790:	6442                	ld	s0,16(sp)
    80002792:	64a2                	ld	s1,8(sp)
    80002794:	6105                	addi	sp,sp,32
    80002796:	8082                	ret

0000000080002798 <killed>:

int killed(struct proc *p)
{
    80002798:	1101                	addi	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	e04a                	sd	s2,0(sp)
    800027a2:	1000                	addi	s0,sp,32
    800027a4:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	492080e7          	jalr	1170(ra) # 80000c38 <acquire>
  k = p->killed;
    800027ae:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800027b2:	8526                	mv	a0,s1
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	538080e7          	jalr	1336(ra) # 80000cec <release>
  return k;
}
    800027bc:	854a                	mv	a0,s2
    800027be:	60e2                	ld	ra,24(sp)
    800027c0:	6442                	ld	s0,16(sp)
    800027c2:	64a2                	ld	s1,8(sp)
    800027c4:	6902                	ld	s2,0(sp)
    800027c6:	6105                	addi	sp,sp,32
    800027c8:	8082                	ret

00000000800027ca <wait>:
{
    800027ca:	715d                	addi	sp,sp,-80
    800027cc:	e486                	sd	ra,72(sp)
    800027ce:	e0a2                	sd	s0,64(sp)
    800027d0:	fc26                	sd	s1,56(sp)
    800027d2:	f84a                	sd	s2,48(sp)
    800027d4:	f44e                	sd	s3,40(sp)
    800027d6:	f052                	sd	s4,32(sp)
    800027d8:	ec56                	sd	s5,24(sp)
    800027da:	e85a                	sd	s6,16(sp)
    800027dc:	e45e                	sd	s7,8(sp)
    800027de:	e062                	sd	s8,0(sp)
    800027e0:	0880                	addi	s0,sp,80
    800027e2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	296080e7          	jalr	662(ra) # 80001a7a <myproc>
    800027ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027ee:	00011517          	auipc	a0,0x11
    800027f2:	e8a50513          	addi	a0,a0,-374 # 80013678 <wait_lock>
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	442080e7          	jalr	1090(ra) # 80000c38 <acquire>
    havekids = 0;
    800027fe:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002800:	4a95                	li	s5,5
        havekids = 1;
    80002802:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002804:	0001f997          	auipc	s3,0x1f
    80002808:	e9c98993          	addi	s3,s3,-356 # 800216a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000280c:	00011c17          	auipc	s8,0x11
    80002810:	e6cc0c13          	addi	s8,s8,-404 # 80013678 <wait_lock>
    80002814:	a0d5                	j	800028f8 <wait+0x12e>
    80002816:	04048613          	addi	a2,s1,64
          for (int i = 0; i <= 25; i++)
    8000281a:	4701                	li	a4,0
    8000281c:	4569                	li	a0,26
            pp->parent->syscall_count[i] += pp->syscall_count[i];
    8000281e:	00271693          	slli	a3,a4,0x2
    80002822:	7c9c                	ld	a5,56(s1)
    80002824:	97b6                	add	a5,a5,a3
    80002826:	43ac                	lw	a1,64(a5)
    80002828:	4214                	lw	a3,0(a2)
    8000282a:	9ead                	addw	a3,a3,a1
    8000282c:	c3b4                	sw	a3,64(a5)
          for (int i = 0; i <= 25; i++)
    8000282e:	2705                	addiw	a4,a4,1
    80002830:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80002832:	fea716e3          	bne	a4,a0,8000281e <wait+0x54>
          pid = pp->pid;
    80002836:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000283a:	000a0e63          	beqz	s4,80002856 <wait+0x8c>
    8000283e:	4691                	li	a3,4
    80002840:	02c48613          	addi	a2,s1,44
    80002844:	85d2                	mv	a1,s4
    80002846:	22893503          	ld	a0,552(s2)
    8000284a:	fffff097          	auipc	ra,0xfffff
    8000284e:	e98080e7          	jalr	-360(ra) # 800016e2 <copyout>
    80002852:	04054163          	bltz	a0,80002894 <wait+0xca>
          freeproc(pp);
    80002856:	8526                	mv	a0,s1
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	3d4080e7          	jalr	980(ra) # 80001c2c <freeproc>
          release(&pp->lock);
    80002860:	8526                	mv	a0,s1
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	48a080e7          	jalr	1162(ra) # 80000cec <release>
          release(&wait_lock);
    8000286a:	00011517          	auipc	a0,0x11
    8000286e:	e0e50513          	addi	a0,a0,-498 # 80013678 <wait_lock>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	47a080e7          	jalr	1146(ra) # 80000cec <release>
}
    8000287a:	854e                	mv	a0,s3
    8000287c:	60a6                	ld	ra,72(sp)
    8000287e:	6406                	ld	s0,64(sp)
    80002880:	74e2                	ld	s1,56(sp)
    80002882:	7942                	ld	s2,48(sp)
    80002884:	79a2                	ld	s3,40(sp)
    80002886:	7a02                	ld	s4,32(sp)
    80002888:	6ae2                	ld	s5,24(sp)
    8000288a:	6b42                	ld	s6,16(sp)
    8000288c:	6ba2                	ld	s7,8(sp)
    8000288e:	6c02                	ld	s8,0(sp)
    80002890:	6161                	addi	sp,sp,80
    80002892:	8082                	ret
            release(&pp->lock);
    80002894:	8526                	mv	a0,s1
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	456080e7          	jalr	1110(ra) # 80000cec <release>
            release(&wait_lock);
    8000289e:	00011517          	auipc	a0,0x11
    800028a2:	dda50513          	addi	a0,a0,-550 # 80013678 <wait_lock>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	446080e7          	jalr	1094(ra) # 80000cec <release>
            return -1;
    800028ae:	59fd                	li	s3,-1
    800028b0:	b7e9                	j	8000287a <wait+0xb0>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028b2:	35048493          	addi	s1,s1,848
    800028b6:	03348463          	beq	s1,s3,800028de <wait+0x114>
      if (pp->parent == p)
    800028ba:	7c9c                	ld	a5,56(s1)
    800028bc:	ff279be3          	bne	a5,s2,800028b2 <wait+0xe8>
        acquire(&pp->lock);
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	376080e7          	jalr	886(ra) # 80000c38 <acquire>
        if (pp->state == ZOMBIE)
    800028ca:	4c9c                	lw	a5,24(s1)
    800028cc:	f55785e3          	beq	a5,s5,80002816 <wait+0x4c>
        release(&pp->lock);
    800028d0:	8526                	mv	a0,s1
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	41a080e7          	jalr	1050(ra) # 80000cec <release>
        havekids = 1;
    800028da:	875a                	mv	a4,s6
    800028dc:	bfd9                	j	800028b2 <wait+0xe8>
    if (!havekids || killed(p))
    800028de:	c31d                	beqz	a4,80002904 <wait+0x13a>
    800028e0:	854a                	mv	a0,s2
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	eb6080e7          	jalr	-330(ra) # 80002798 <killed>
    800028ea:	ed09                	bnez	a0,80002904 <wait+0x13a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028ec:	85e2                	mv	a1,s8
    800028ee:	854a                	mv	a0,s2
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	bf4080e7          	jalr	-1036(ra) # 800024e4 <sleep>
    havekids = 0;
    800028f8:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028fa:	00012497          	auipc	s1,0x12
    800028fe:	9a648493          	addi	s1,s1,-1626 # 800142a0 <proc>
    80002902:	bf65                	j	800028ba <wait+0xf0>
      release(&wait_lock);
    80002904:	00011517          	auipc	a0,0x11
    80002908:	d7450513          	addi	a0,a0,-652 # 80013678 <wait_lock>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	3e0080e7          	jalr	992(ra) # 80000cec <release>
      return -1;
    80002914:	59fd                	li	s3,-1
    80002916:	b795                	j	8000287a <wait+0xb0>

0000000080002918 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002918:	7179                	addi	sp,sp,-48
    8000291a:	f406                	sd	ra,40(sp)
    8000291c:	f022                	sd	s0,32(sp)
    8000291e:	ec26                	sd	s1,24(sp)
    80002920:	e84a                	sd	s2,16(sp)
    80002922:	e44e                	sd	s3,8(sp)
    80002924:	e052                	sd	s4,0(sp)
    80002926:	1800                	addi	s0,sp,48
    80002928:	84aa                	mv	s1,a0
    8000292a:	892e                	mv	s2,a1
    8000292c:	89b2                	mv	s3,a2
    8000292e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	14a080e7          	jalr	330(ra) # 80001a7a <myproc>
  if (user_dst)
    80002938:	c095                	beqz	s1,8000295c <either_copyout+0x44>
  {
    return copyout(p->pagetable, dst, src, len);
    8000293a:	86d2                	mv	a3,s4
    8000293c:	864e                	mv	a2,s3
    8000293e:	85ca                	mv	a1,s2
    80002940:	22853503          	ld	a0,552(a0)
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	d9e080e7          	jalr	-610(ra) # 800016e2 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000294c:	70a2                	ld	ra,40(sp)
    8000294e:	7402                	ld	s0,32(sp)
    80002950:	64e2                	ld	s1,24(sp)
    80002952:	6942                	ld	s2,16(sp)
    80002954:	69a2                	ld	s3,8(sp)
    80002956:	6a02                	ld	s4,0(sp)
    80002958:	6145                	addi	sp,sp,48
    8000295a:	8082                	ret
    memmove((char *)dst, src, len);
    8000295c:	000a061b          	sext.w	a2,s4
    80002960:	85ce                	mv	a1,s3
    80002962:	854a                	mv	a0,s2
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	42c080e7          	jalr	1068(ra) # 80000d90 <memmove>
    return 0;
    8000296c:	8526                	mv	a0,s1
    8000296e:	bff9                	j	8000294c <either_copyout+0x34>

0000000080002970 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002970:	7179                	addi	sp,sp,-48
    80002972:	f406                	sd	ra,40(sp)
    80002974:	f022                	sd	s0,32(sp)
    80002976:	ec26                	sd	s1,24(sp)
    80002978:	e84a                	sd	s2,16(sp)
    8000297a:	e44e                	sd	s3,8(sp)
    8000297c:	e052                	sd	s4,0(sp)
    8000297e:	1800                	addi	s0,sp,48
    80002980:	892a                	mv	s2,a0
    80002982:	84ae                	mv	s1,a1
    80002984:	89b2                	mv	s3,a2
    80002986:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002988:	fffff097          	auipc	ra,0xfffff
    8000298c:	0f2080e7          	jalr	242(ra) # 80001a7a <myproc>
  if (user_src)
    80002990:	c095                	beqz	s1,800029b4 <either_copyin+0x44>
  {
    return copyin(p->pagetable, dst, src, len);
    80002992:	86d2                	mv	a3,s4
    80002994:	864e                	mv	a2,s3
    80002996:	85ca                	mv	a1,s2
    80002998:	22853503          	ld	a0,552(a0)
    8000299c:	fffff097          	auipc	ra,0xfffff
    800029a0:	dd2080e7          	jalr	-558(ra) # 8000176e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800029a4:	70a2                	ld	ra,40(sp)
    800029a6:	7402                	ld	s0,32(sp)
    800029a8:	64e2                	ld	s1,24(sp)
    800029aa:	6942                	ld	s2,16(sp)
    800029ac:	69a2                	ld	s3,8(sp)
    800029ae:	6a02                	ld	s4,0(sp)
    800029b0:	6145                	addi	sp,sp,48
    800029b2:	8082                	ret
    memmove(dst, (char *)src, len);
    800029b4:	000a061b          	sext.w	a2,s4
    800029b8:	85ce                	mv	a1,s3
    800029ba:	854a                	mv	a0,s2
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	3d4080e7          	jalr	980(ra) # 80000d90 <memmove>
    return 0;
    800029c4:	8526                	mv	a0,s1
    800029c6:	bff9                	j	800029a4 <either_copyin+0x34>

00000000800029c8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800029c8:	715d                	addi	sp,sp,-80
    800029ca:	e486                	sd	ra,72(sp)
    800029cc:	e0a2                	sd	s0,64(sp)
    800029ce:	fc26                	sd	s1,56(sp)
    800029d0:	f84a                	sd	s2,48(sp)
    800029d2:	f44e                	sd	s3,40(sp)
    800029d4:	f052                	sd	s4,32(sp)
    800029d6:	ec56                	sd	s5,24(sp)
    800029d8:	e85a                	sd	s6,16(sp)
    800029da:	e45e                	sd	s7,8(sp)
    800029dc:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800029de:	00005517          	auipc	a0,0x5
    800029e2:	63250513          	addi	a0,a0,1586 # 80008010 <etext+0x10>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	bc4080e7          	jalr	-1084(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029ee:	00012497          	auipc	s1,0x12
    800029f2:	be248493          	addi	s1,s1,-1054 # 800145d0 <proc+0x330>
    800029f6:	0001f917          	auipc	s2,0x1f
    800029fa:	fda90913          	addi	s2,s2,-38 # 800219d0 <bcache+0x318>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029fe:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a00:	00006997          	auipc	s3,0x6
    80002a04:	86098993          	addi	s3,s3,-1952 # 80008260 <etext+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002a08:	00006a97          	auipc	s5,0x6
    80002a0c:	860a8a93          	addi	s5,s5,-1952 # 80008268 <etext+0x268>
    printf("\n");
    80002a10:	00005a17          	auipc	s4,0x5
    80002a14:	600a0a13          	addi	s4,s4,1536 # 80008010 <etext+0x10>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a18:	00006b97          	auipc	s7,0x6
    80002a1c:	d28b8b93          	addi	s7,s7,-728 # 80008740 <states.0>
    80002a20:	a00d                	j	80002a42 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a22:	d006a583          	lw	a1,-768(a3)
    80002a26:	8556                	mv	a0,s5
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b82080e7          	jalr	-1150(ra) # 800005aa <printf>
    printf("\n");
    80002a30:	8552                	mv	a0,s4
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	b78080e7          	jalr	-1160(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a3a:	35048493          	addi	s1,s1,848
    80002a3e:	03248263          	beq	s1,s2,80002a62 <procdump+0x9a>
    if (p->state == UNUSED)
    80002a42:	86a6                	mv	a3,s1
    80002a44:	ce84a783          	lw	a5,-792(s1)
    80002a48:	dbed                	beqz	a5,80002a3a <procdump+0x72>
      state = "???";
    80002a4a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a4c:	fcfb6be3          	bltu	s6,a5,80002a22 <procdump+0x5a>
    80002a50:	02079713          	slli	a4,a5,0x20
    80002a54:	01d75793          	srli	a5,a4,0x1d
    80002a58:	97de                	add	a5,a5,s7
    80002a5a:	6390                	ld	a2,0(a5)
    80002a5c:	f279                	bnez	a2,80002a22 <procdump+0x5a>
      state = "???";
    80002a5e:	864e                	mv	a2,s3
    80002a60:	b7c9                	j	80002a22 <procdump+0x5a>
  }
}
    80002a62:	60a6                	ld	ra,72(sp)
    80002a64:	6406                	ld	s0,64(sp)
    80002a66:	74e2                	ld	s1,56(sp)
    80002a68:	7942                	ld	s2,48(sp)
    80002a6a:	79a2                	ld	s3,40(sp)
    80002a6c:	7a02                	ld	s4,32(sp)
    80002a6e:	6ae2                	ld	s5,24(sp)
    80002a70:	6b42                	ld	s6,16(sp)
    80002a72:	6ba2                	ld	s7,8(sp)
    80002a74:	6161                	addi	sp,sp,80
    80002a76:	8082                	ret

0000000080002a78 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002a78:	711d                	addi	sp,sp,-96
    80002a7a:	ec86                	sd	ra,88(sp)
    80002a7c:	e8a2                	sd	s0,80(sp)
    80002a7e:	e4a6                	sd	s1,72(sp)
    80002a80:	e0ca                	sd	s2,64(sp)
    80002a82:	fc4e                	sd	s3,56(sp)
    80002a84:	f852                	sd	s4,48(sp)
    80002a86:	f456                	sd	s5,40(sp)
    80002a88:	f05a                	sd	s6,32(sp)
    80002a8a:	ec5e                	sd	s7,24(sp)
    80002a8c:	e862                	sd	s8,16(sp)
    80002a8e:	e466                	sd	s9,8(sp)
    80002a90:	e06a                	sd	s10,0(sp)
    80002a92:	1080                	addi	s0,sp,96
    80002a94:	8b2a                	mv	s6,a0
    80002a96:	8bae                	mv	s7,a1
    80002a98:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	fe0080e7          	jalr	-32(ra) # 80001a7a <myproc>
    80002aa2:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002aa4:	00011517          	auipc	a0,0x11
    80002aa8:	bd450513          	addi	a0,a0,-1068 # 80013678 <wait_lock>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	18c080e7          	jalr	396(ra) # 80000c38 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002ab4:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002ab6:	4a15                	li	s4,5
        havekids = 1;
    80002ab8:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002aba:	0001f997          	auipc	s3,0x1f
    80002abe:	be698993          	addi	s3,s3,-1050 # 800216a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002ac2:	00011d17          	auipc	s10,0x11
    80002ac6:	bb6d0d13          	addi	s10,s10,-1098 # 80013678 <wait_lock>
    80002aca:	a8e9                	j	80002ba4 <waitx+0x12c>
          pid = np->pid;
    80002acc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002ad0:	3404a783          	lw	a5,832(s1)
    80002ad4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002ad8:	3444a703          	lw	a4,836(s1)
    80002adc:	9f3d                	addw	a4,a4,a5
    80002ade:	3484a783          	lw	a5,840(s1)
    80002ae2:	9f99                	subw	a5,a5,a4
    80002ae4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002ae8:	000b0e63          	beqz	s6,80002b04 <waitx+0x8c>
    80002aec:	4691                	li	a3,4
    80002aee:	02c48613          	addi	a2,s1,44
    80002af2:	85da                	mv	a1,s6
    80002af4:	22893503          	ld	a0,552(s2)
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	bea080e7          	jalr	-1046(ra) # 800016e2 <copyout>
    80002b00:	04054363          	bltz	a0,80002b46 <waitx+0xce>
          freeproc(np);
    80002b04:	8526                	mv	a0,s1
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	126080e7          	jalr	294(ra) # 80001c2c <freeproc>
          release(&np->lock);
    80002b0e:	8526                	mv	a0,s1
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	1dc080e7          	jalr	476(ra) # 80000cec <release>
          release(&wait_lock);
    80002b18:	00011517          	auipc	a0,0x11
    80002b1c:	b6050513          	addi	a0,a0,-1184 # 80013678 <wait_lock>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	1cc080e7          	jalr	460(ra) # 80000cec <release>
  }
}
    80002b28:	854e                	mv	a0,s3
    80002b2a:	60e6                	ld	ra,88(sp)
    80002b2c:	6446                	ld	s0,80(sp)
    80002b2e:	64a6                	ld	s1,72(sp)
    80002b30:	6906                	ld	s2,64(sp)
    80002b32:	79e2                	ld	s3,56(sp)
    80002b34:	7a42                	ld	s4,48(sp)
    80002b36:	7aa2                	ld	s5,40(sp)
    80002b38:	7b02                	ld	s6,32(sp)
    80002b3a:	6be2                	ld	s7,24(sp)
    80002b3c:	6c42                	ld	s8,16(sp)
    80002b3e:	6ca2                	ld	s9,8(sp)
    80002b40:	6d02                	ld	s10,0(sp)
    80002b42:	6125                	addi	sp,sp,96
    80002b44:	8082                	ret
            release(&np->lock);
    80002b46:	8526                	mv	a0,s1
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	1a4080e7          	jalr	420(ra) # 80000cec <release>
            release(&wait_lock);
    80002b50:	00011517          	auipc	a0,0x11
    80002b54:	b2850513          	addi	a0,a0,-1240 # 80013678 <wait_lock>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	194080e7          	jalr	404(ra) # 80000cec <release>
            return -1;
    80002b60:	59fd                	li	s3,-1
    80002b62:	b7d9                	j	80002b28 <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002b64:	35048493          	addi	s1,s1,848
    80002b68:	03348463          	beq	s1,s3,80002b90 <waitx+0x118>
      if (np->parent == p)
    80002b6c:	7c9c                	ld	a5,56(s1)
    80002b6e:	ff279be3          	bne	a5,s2,80002b64 <waitx+0xec>
        acquire(&np->lock);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	0c4080e7          	jalr	196(ra) # 80000c38 <acquire>
        if (np->state == ZOMBIE)
    80002b7c:	4c9c                	lw	a5,24(s1)
    80002b7e:	f54787e3          	beq	a5,s4,80002acc <waitx+0x54>
        release(&np->lock);
    80002b82:	8526                	mv	a0,s1
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	168080e7          	jalr	360(ra) # 80000cec <release>
        havekids = 1;
    80002b8c:	8756                	mv	a4,s5
    80002b8e:	bfd9                	j	80002b64 <waitx+0xec>
    if (!havekids || p->killed)
    80002b90:	c305                	beqz	a4,80002bb0 <waitx+0x138>
    80002b92:	02892783          	lw	a5,40(s2)
    80002b96:	ef89                	bnez	a5,80002bb0 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b98:	85ea                	mv	a1,s10
    80002b9a:	854a                	mv	a0,s2
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	948080e7          	jalr	-1720(ra) # 800024e4 <sleep>
    havekids = 0;
    80002ba4:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002ba6:	00011497          	auipc	s1,0x11
    80002baa:	6fa48493          	addi	s1,s1,1786 # 800142a0 <proc>
    80002bae:	bf7d                	j	80002b6c <waitx+0xf4>
      release(&wait_lock);
    80002bb0:	00011517          	auipc	a0,0x11
    80002bb4:	ac850513          	addi	a0,a0,-1336 # 80013678 <wait_lock>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	134080e7          	jalr	308(ra) # 80000cec <release>
      return -1;
    80002bc0:	59fd                	li	s3,-1
    80002bc2:	b79d                	j	80002b28 <waitx+0xb0>

0000000080002bc4 <update_time>:

void update_time()
{
    80002bc4:	7179                	addi	sp,sp,-48
    80002bc6:	f406                	sd	ra,40(sp)
    80002bc8:	f022                	sd	s0,32(sp)
    80002bca:	ec26                	sd	s1,24(sp)
    80002bcc:	e84a                	sd	s2,16(sp)
    80002bce:	e44e                	sd	s3,8(sp)
    80002bd0:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002bd2:	00011497          	auipc	s1,0x11
    80002bd6:	6ce48493          	addi	s1,s1,1742 # 800142a0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002bda:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002bdc:	0001f917          	auipc	s2,0x1f
    80002be0:	ac490913          	addi	s2,s2,-1340 # 800216a0 <tickslock>
    80002be4:	a811                	j	80002bf8 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002be6:	8526                	mv	a0,s1
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	104080e7          	jalr	260(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bf0:	35048493          	addi	s1,s1,848
    80002bf4:	03248063          	beq	s1,s2,80002c14 <update_time+0x50>
    acquire(&p->lock);
    80002bf8:	8526                	mv	a0,s1
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	03e080e7          	jalr	62(ra) # 80000c38 <acquire>
    if (p->state == RUNNING)
    80002c02:	4c9c                	lw	a5,24(s1)
    80002c04:	ff3791e3          	bne	a5,s3,80002be6 <update_time+0x22>
      p->rtime++;
    80002c08:	3404a783          	lw	a5,832(s1)
    80002c0c:	2785                	addiw	a5,a5,1
    80002c0e:	34f4a023          	sw	a5,832(s1)
    80002c12:	bfd1                	j	80002be6 <update_time+0x22>
  }
    80002c14:	70a2                	ld	ra,40(sp)
    80002c16:	7402                	ld	s0,32(sp)
    80002c18:	64e2                	ld	s1,24(sp)
    80002c1a:	6942                	ld	s2,16(sp)
    80002c1c:	69a2                	ld	s3,8(sp)
    80002c1e:	6145                	addi	sp,sp,48
    80002c20:	8082                	ret

0000000080002c22 <swtch>:
    80002c22:	00153023          	sd	ra,0(a0)
    80002c26:	00253423          	sd	sp,8(a0)
    80002c2a:	e900                	sd	s0,16(a0)
    80002c2c:	ed04                	sd	s1,24(a0)
    80002c2e:	03253023          	sd	s2,32(a0)
    80002c32:	03353423          	sd	s3,40(a0)
    80002c36:	03453823          	sd	s4,48(a0)
    80002c3a:	03553c23          	sd	s5,56(a0)
    80002c3e:	05653023          	sd	s6,64(a0)
    80002c42:	05753423          	sd	s7,72(a0)
    80002c46:	05853823          	sd	s8,80(a0)
    80002c4a:	05953c23          	sd	s9,88(a0)
    80002c4e:	07a53023          	sd	s10,96(a0)
    80002c52:	07b53423          	sd	s11,104(a0)
    80002c56:	0005b083          	ld	ra,0(a1)
    80002c5a:	0085b103          	ld	sp,8(a1)
    80002c5e:	6980                	ld	s0,16(a1)
    80002c60:	6d84                	ld	s1,24(a1)
    80002c62:	0205b903          	ld	s2,32(a1)
    80002c66:	0285b983          	ld	s3,40(a1)
    80002c6a:	0305ba03          	ld	s4,48(a1)
    80002c6e:	0385ba83          	ld	s5,56(a1)
    80002c72:	0405bb03          	ld	s6,64(a1)
    80002c76:	0485bb83          	ld	s7,72(a1)
    80002c7a:	0505bc03          	ld	s8,80(a1)
    80002c7e:	0585bc83          	ld	s9,88(a1)
    80002c82:	0605bd03          	ld	s10,96(a1)
    80002c86:	0685bd83          	ld	s11,104(a1)
    80002c8a:	8082                	ret

0000000080002c8c <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002c8c:	1141                	addi	sp,sp,-16
    80002c8e:	e406                	sd	ra,8(sp)
    80002c90:	e022                	sd	s0,0(sp)
    80002c92:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c94:	00005597          	auipc	a1,0x5
    80002c98:	61458593          	addi	a1,a1,1556 # 800082a8 <etext+0x2a8>
    80002c9c:	0001f517          	auipc	a0,0x1f
    80002ca0:	a0450513          	addi	a0,a0,-1532 # 800216a0 <tickslock>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	f04080e7          	jalr	-252(ra) # 80000ba8 <initlock>
}
    80002cac:	60a2                	ld	ra,8(sp)
    80002cae:	6402                	ld	s0,0(sp)
    80002cb0:	0141                	addi	sp,sp,16
    80002cb2:	8082                	ret

0000000080002cb4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002cb4:	1141                	addi	sp,sp,-16
    80002cb6:	e422                	sd	s0,8(sp)
    80002cb8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cba:	00003797          	auipc	a5,0x3
    80002cbe:	7e678793          	addi	a5,a5,2022 # 800064a0 <kernelvec>
    80002cc2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cc6:	6422                	ld	s0,8(sp)
    80002cc8:	0141                	addi	sp,sp,16
    80002cca:	8082                	ret

0000000080002ccc <usertrapret>:
}

// return to user space
//
void usertrapret(void)
{
    80002ccc:	1141                	addi	sp,sp,-16
    80002cce:	e406                	sd	ra,8(sp)
    80002cd0:	e022                	sd	s0,0(sp)
    80002cd2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	da6080e7          	jalr	-602(ra) # 80001a7a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cdc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ce0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ce6:	00004697          	auipc	a3,0x4
    80002cea:	31a68693          	addi	a3,a3,794 # 80007000 <_trampoline>
    80002cee:	00004717          	auipc	a4,0x4
    80002cf2:	31270713          	addi	a4,a4,786 # 80007000 <_trampoline>
    80002cf6:	8f15                	sub	a4,a4,a3
    80002cf8:	040007b7          	lui	a5,0x4000
    80002cfc:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002cfe:	07b2                	slli	a5,a5,0xc
    80002d00:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d02:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d06:	23053703          	ld	a4,560(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d0a:	18002673          	csrr	a2,satp
    80002d0e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d10:	23053603          	ld	a2,560(a0)
    80002d14:	21853703          	ld	a4,536(a0)
    80002d18:	6585                	lui	a1,0x1
    80002d1a:	972e                	add	a4,a4,a1
    80002d1c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d1e:	23053703          	ld	a4,560(a0)
    80002d22:	00000617          	auipc	a2,0x0
    80002d26:	14c60613          	addi	a2,a2,332 # 80002e6e <usertrap>
    80002d2a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002d2c:	23053703          	ld	a4,560(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d30:	8612                	mv	a2,tp
    80002d32:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d34:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d38:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d3c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d40:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d44:	23053703          	ld	a4,560(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d48:	6f18                	ld	a4,24(a4)
    80002d4a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d4e:	22853503          	ld	a0,552(a0)
    80002d52:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d54:	00004717          	auipc	a4,0x4
    80002d58:	34870713          	addi	a4,a4,840 # 8000709c <userret>
    80002d5c:	8f15                	sub	a4,a4,a3
    80002d5e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002d60:	577d                	li	a4,-1
    80002d62:	177e                	slli	a4,a4,0x3f
    80002d64:	8d59                	or	a0,a0,a4
    80002d66:	9782                	jalr	a5
}
    80002d68:	60a2                	ld	ra,8(sp)
    80002d6a:	6402                	ld	s0,0(sp)
    80002d6c:	0141                	addi	sp,sp,16
    80002d6e:	8082                	ret

0000000080002d70 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002d70:	1101                	addi	sp,sp,-32
    80002d72:	ec06                	sd	ra,24(sp)
    80002d74:	e822                	sd	s0,16(sp)
    80002d76:	e426                	sd	s1,8(sp)
    80002d78:	e04a                	sd	s2,0(sp)
    80002d7a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d7c:	0001f917          	auipc	s2,0x1f
    80002d80:	92490913          	addi	s2,s2,-1756 # 800216a0 <tickslock>
    80002d84:	854a                	mv	a0,s2
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	eb2080e7          	jalr	-334(ra) # 80000c38 <acquire>
  ticks++;
    80002d8e:	00008497          	auipc	s1,0x8
    80002d92:	66648493          	addi	s1,s1,1638 # 8000b3f4 <ticks>
    80002d96:	409c                	lw	a5,0(s1)
    80002d98:	2785                	addiw	a5,a5,1
    80002d9a:	c09c                	sw	a5,0(s1)
  update_time();
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	e28080e7          	jalr	-472(ra) # 80002bc4 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002da4:	8526                	mv	a0,s1
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	7a2080e7          	jalr	1954(ra) # 80002548 <wakeup>
  release(&tickslock);
    80002dae:	854a                	mv	a0,s2
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	f3c080e7          	jalr	-196(ra) # 80000cec <release>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6902                	ld	s2,0(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dc4:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002dc8:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002dca:	0a07d163          	bgez	a5,80002e6c <devintr+0xa8>
{
    80002dce:	1101                	addi	sp,sp,-32
    80002dd0:	ec06                	sd	ra,24(sp)
    80002dd2:	e822                	sd	s0,16(sp)
    80002dd4:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002dd6:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002dda:	46a5                	li	a3,9
    80002ddc:	00d70c63          	beq	a4,a3,80002df4 <devintr+0x30>
  else if (scause == 0x8000000000000001L)
    80002de0:	577d                	li	a4,-1
    80002de2:	177e                	slli	a4,a4,0x3f
    80002de4:	0705                	addi	a4,a4,1
    return 0;
    80002de6:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002de8:	06e78163          	beq	a5,a4,80002e4a <devintr+0x86>
  }
}
    80002dec:	60e2                	ld	ra,24(sp)
    80002dee:	6442                	ld	s0,16(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret
    80002df4:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002df6:	00003097          	auipc	ra,0x3
    80002dfa:	7b6080e7          	jalr	1974(ra) # 800065ac <plic_claim>
    80002dfe:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002e00:	47a9                	li	a5,10
    80002e02:	00f50963          	beq	a0,a5,80002e14 <devintr+0x50>
    else if (irq == VIRTIO0_IRQ)
    80002e06:	4785                	li	a5,1
    80002e08:	00f50b63          	beq	a0,a5,80002e1e <devintr+0x5a>
    return 1;
    80002e0c:	4505                	li	a0,1
    else if (irq)
    80002e0e:	ec89                	bnez	s1,80002e28 <devintr+0x64>
    80002e10:	64a2                	ld	s1,8(sp)
    80002e12:	bfe9                	j	80002dec <devintr+0x28>
      uartintr();
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	be6080e7          	jalr	-1050(ra) # 800009fa <uartintr>
    if (irq)
    80002e1c:	a839                	j	80002e3a <devintr+0x76>
      virtio_disk_intr();
    80002e1e:	00004097          	auipc	ra,0x4
    80002e22:	cb8080e7          	jalr	-840(ra) # 80006ad6 <virtio_disk_intr>
    if (irq)
    80002e26:	a811                	j	80002e3a <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e28:	85a6                	mv	a1,s1
    80002e2a:	00005517          	auipc	a0,0x5
    80002e2e:	48650513          	addi	a0,a0,1158 # 800082b0 <etext+0x2b0>
    80002e32:	ffffd097          	auipc	ra,0xffffd
    80002e36:	778080e7          	jalr	1912(ra) # 800005aa <printf>
      plic_complete(irq);
    80002e3a:	8526                	mv	a0,s1
    80002e3c:	00003097          	auipc	ra,0x3
    80002e40:	794080e7          	jalr	1940(ra) # 800065d0 <plic_complete>
    return 1;
    80002e44:	4505                	li	a0,1
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	b755                	j	80002dec <devintr+0x28>
    if (cpuid() == 0)
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	c04080e7          	jalr	-1020(ra) # 80001a4e <cpuid>
    80002e52:	c901                	beqz	a0,80002e62 <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e54:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e58:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e5a:	14479073          	csrw	sip,a5
    return 2;
    80002e5e:	4509                	li	a0,2
    80002e60:	b771                	j	80002dec <devintr+0x28>
      clockintr();
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	f0e080e7          	jalr	-242(ra) # 80002d70 <clockintr>
    80002e6a:	b7ed                	j	80002e54 <devintr+0x90>
}
    80002e6c:	8082                	ret

0000000080002e6e <usertrap>:
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e78:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002e7c:	1007f793          	andi	a5,a5,256
    80002e80:	ebad                	bnez	a5,80002ef2 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e82:	00003797          	auipc	a5,0x3
    80002e86:	61e78793          	addi	a5,a5,1566 # 800064a0 <kernelvec>
    80002e8a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	bec080e7          	jalr	-1044(ra) # 80001a7a <myproc>
    80002e96:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e98:	23053783          	ld	a5,560(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e9c:	14102773          	csrr	a4,sepc
    80002ea0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ea2:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002ea6:	47a1                	li	a5,8
    80002ea8:	04f70d63          	beq	a4,a5,80002f02 <usertrap+0x94>
  else if ((which_dev = devintr()) != 0)
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	f18080e7          	jalr	-232(ra) # 80002dc4 <devintr>
    80002eb4:	c145                	beqz	a0,80002f54 <usertrap+0xe6>
  if (which_dev == 2 && p->interval > 0)
    80002eb6:	4789                	li	a5,2
    80002eb8:	06f51963          	bne	a0,a5,80002f2a <usertrap+0xbc>
    80002ebc:	0e44a703          	lw	a4,228(s1)
    80002ec0:	00e05e63          	blez	a4,80002edc <usertrap+0x6e>
    p->ticks++;
    80002ec4:	0e04a783          	lw	a5,224(s1)
    80002ec8:	2785                	addiw	a5,a5,1
    80002eca:	0007869b          	sext.w	a3,a5
    80002ece:	0ef4a023          	sw	a5,224(s1)
    if (p->ticks >= p->interval && p->alarm_set == 0)
    80002ed2:	00e6c563          	blt	a3,a4,80002edc <usertrap+0x6e>
    80002ed6:	2104a783          	lw	a5,528(s1)
    80002eda:	cbd5                	beqz	a5,80002f8e <usertrap+0x120>
  if (killed(p))
    80002edc:	8526                	mv	a0,s1
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	8ba080e7          	jalr	-1862(ra) # 80002798 <killed>
    80002ee6:	e961                	bnez	a0,80002fb6 <usertrap+0x148>
    yield();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	5c0080e7          	jalr	1472(ra) # 800024a8 <yield>
    80002ef0:	a099                	j	80002f36 <usertrap+0xc8>
    panic("usertrap: not from user mode");
    80002ef2:	00005517          	auipc	a0,0x5
    80002ef6:	3de50513          	addi	a0,a0,990 # 800082d0 <etext+0x2d0>
    80002efa:	ffffd097          	auipc	ra,0xffffd
    80002efe:	666080e7          	jalr	1638(ra) # 80000560 <panic>
    if (killed(p))
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	896080e7          	jalr	-1898(ra) # 80002798 <killed>
    80002f0a:	ed1d                	bnez	a0,80002f48 <usertrap+0xda>
    p->trapframe->epc += 4;
    80002f0c:	2304b703          	ld	a4,560(s1)
    80002f10:	6f1c                	ld	a5,24(a4)
    80002f12:	0791                	addi	a5,a5,4
    80002f14:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f1e:	10079073          	csrw	sstatus,a5
    syscall();
    80002f22:	00000097          	auipc	ra,0x0
    80002f26:	308080e7          	jalr	776(ra) # 8000322a <syscall>
  if (killed(p))
    80002f2a:	8526                	mv	a0,s1
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	86c080e7          	jalr	-1940(ra) # 80002798 <killed>
    80002f34:	e559                	bnez	a0,80002fc2 <usertrap+0x154>
  usertrapret();
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	d96080e7          	jalr	-618(ra) # 80002ccc <usertrapret>
}
    80002f3e:	60e2                	ld	ra,24(sp)
    80002f40:	6442                	ld	s0,16(sp)
    80002f42:	64a2                	ld	s1,8(sp)
    80002f44:	6105                	addi	sp,sp,32
    80002f46:	8082                	ret
      exit(-1);
    80002f48:	557d                	li	a0,-1
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	6ce080e7          	jalr	1742(ra) # 80002618 <exit>
    80002f52:	bf6d                	j	80002f0c <usertrap+0x9e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f58:	5890                	lw	a2,48(s1)
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	39650513          	addi	a0,a0,918 # 800082f0 <etext+0x2f0>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	648080e7          	jalr	1608(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	3ae50513          	addi	a0,a0,942 # 80008320 <etext+0x320>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	630080e7          	jalr	1584(ra) # 800005aa <printf>
    setkilled(p);
    80002f82:	8526                	mv	a0,s1
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	7e8080e7          	jalr	2024(ra) # 8000276c <setkilled>
  if (which_dev == 2 && p->interval > 0)
    80002f8c:	bf79                	j	80002f2a <usertrap+0xbc>
      p->ticks = 0;
    80002f8e:	0e04a023          	sw	zero,224(s1)
      p->alarm_set = 1; 
    80002f92:	4785                	li	a5,1
    80002f94:	20f4a823          	sw	a5,528(s1)
      memmove(&p->saved_alarm_tf, p->trapframe, sizeof(struct trapframe));
    80002f98:	12000613          	li	a2,288
    80002f9c:	2304b583          	ld	a1,560(s1)
    80002fa0:	0f048513          	addi	a0,s1,240
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	dec080e7          	jalr	-532(ra) # 80000d90 <memmove>
      p->trapframe->epc = p->handler_addr;
    80002fac:	2304b783          	ld	a5,560(s1)
    80002fb0:	74f8                	ld	a4,232(s1)
    80002fb2:	ef98                	sd	a4,24(a5)
    80002fb4:	b725                	j	80002edc <usertrap+0x6e>
    exit(-1);
    80002fb6:	557d                	li	a0,-1
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	660080e7          	jalr	1632(ra) # 80002618 <exit>
  if (which_dev == 2)
    80002fc0:	b725                	j	80002ee8 <usertrap+0x7a>
    exit(-1);
    80002fc2:	557d                	li	a0,-1
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	654080e7          	jalr	1620(ra) # 80002618 <exit>
  if (which_dev == 2)
    80002fcc:	b7ad                	j	80002f36 <usertrap+0xc8>

0000000080002fce <kerneltrap>:
{
    80002fce:	7179                	addi	sp,sp,-48
    80002fd0:	f406                	sd	ra,40(sp)
    80002fd2:	f022                	sd	s0,32(sp)
    80002fd4:	ec26                	sd	s1,24(sp)
    80002fd6:	e84a                	sd	s2,16(sp)
    80002fd8:	e44e                	sd	s3,8(sp)
    80002fda:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fdc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fe4:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002fe8:	1004f793          	andi	a5,s1,256
    80002fec:	cb85                	beqz	a5,8000301c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fee:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ff2:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002ff4:	ef85                	bnez	a5,8000302c <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	dce080e7          	jalr	-562(ra) # 80002dc4 <devintr>
    80002ffe:	cd1d                	beqz	a0,8000303c <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003000:	4789                	li	a5,2
    80003002:	06f50a63          	beq	a0,a5,80003076 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003006:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000300a:	10049073          	csrw	sstatus,s1
}
    8000300e:	70a2                	ld	ra,40(sp)
    80003010:	7402                	ld	s0,32(sp)
    80003012:	64e2                	ld	s1,24(sp)
    80003014:	6942                	ld	s2,16(sp)
    80003016:	69a2                	ld	s3,8(sp)
    80003018:	6145                	addi	sp,sp,48
    8000301a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000301c:	00005517          	auipc	a0,0x5
    80003020:	32450513          	addi	a0,a0,804 # 80008340 <etext+0x340>
    80003024:	ffffd097          	auipc	ra,0xffffd
    80003028:	53c080e7          	jalr	1340(ra) # 80000560 <panic>
    panic("kerneltrap: interrupts enabled");
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	33c50513          	addi	a0,a0,828 # 80008368 <etext+0x368>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	52c080e7          	jalr	1324(ra) # 80000560 <panic>
    printf("scause %p\n", scause);
    8000303c:	85ce                	mv	a1,s3
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	34a50513          	addi	a0,a0,842 # 80008388 <etext+0x388>
    80003046:	ffffd097          	auipc	ra,0xffffd
    8000304a:	564080e7          	jalr	1380(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000304e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003052:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	34250513          	addi	a0,a0,834 # 80008398 <etext+0x398>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	54c080e7          	jalr	1356(ra) # 800005aa <printf>
    panic("kerneltrap");
    80003066:	00005517          	auipc	a0,0x5
    8000306a:	34a50513          	addi	a0,a0,842 # 800083b0 <etext+0x3b0>
    8000306e:	ffffd097          	auipc	ra,0xffffd
    80003072:	4f2080e7          	jalr	1266(ra) # 80000560 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	a04080e7          	jalr	-1532(ra) # 80001a7a <myproc>
    8000307e:	d541                	beqz	a0,80003006 <kerneltrap+0x38>
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	9fa080e7          	jalr	-1542(ra) # 80001a7a <myproc>
    80003088:	4d18                	lw	a4,24(a0)
    8000308a:	4791                	li	a5,4
    8000308c:	f6f71de3          	bne	a4,a5,80003006 <kerneltrap+0x38>
    yield();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	418080e7          	jalr	1048(ra) # 800024a8 <yield>
    80003098:	b7bd                	j	80003006 <kerneltrap+0x38>

000000008000309a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030a6:	fffff097          	auipc	ra,0xfffff
    800030aa:	9d4080e7          	jalr	-1580(ra) # 80001a7a <myproc>
  switch (n) {
    800030ae:	4795                	li	a5,5
    800030b0:	0497e763          	bltu	a5,s1,800030fe <argraw+0x64>
    800030b4:	048a                	slli	s1,s1,0x2
    800030b6:	00005717          	auipc	a4,0x5
    800030ba:	6ba70713          	addi	a4,a4,1722 # 80008770 <states.0+0x30>
    800030be:	94ba                	add	s1,s1,a4
    800030c0:	409c                	lw	a5,0(s1)
    800030c2:	97ba                	add	a5,a5,a4
    800030c4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030c6:	23053783          	ld	a5,560(a0)
    800030ca:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret
    return p->trapframe->a1;
    800030d6:	23053783          	ld	a5,560(a0)
    800030da:	7fa8                	ld	a0,120(a5)
    800030dc:	bfc5                	j	800030cc <argraw+0x32>
    return p->trapframe->a2;
    800030de:	23053783          	ld	a5,560(a0)
    800030e2:	63c8                	ld	a0,128(a5)
    800030e4:	b7e5                	j	800030cc <argraw+0x32>
    return p->trapframe->a3;
    800030e6:	23053783          	ld	a5,560(a0)
    800030ea:	67c8                	ld	a0,136(a5)
    800030ec:	b7c5                	j	800030cc <argraw+0x32>
    return p->trapframe->a4;
    800030ee:	23053783          	ld	a5,560(a0)
    800030f2:	6bc8                	ld	a0,144(a5)
    800030f4:	bfe1                	j	800030cc <argraw+0x32>
    return p->trapframe->a5;
    800030f6:	23053783          	ld	a5,560(a0)
    800030fa:	6fc8                	ld	a0,152(a5)
    800030fc:	bfc1                	j	800030cc <argraw+0x32>
  panic("argraw");
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	2c250513          	addi	a0,a0,706 # 800083c0 <etext+0x3c0>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	45a080e7          	jalr	1114(ra) # 80000560 <panic>

000000008000310e <fetchaddr>:
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	e04a                	sd	s2,0(sp)
    80003118:	1000                	addi	s0,sp,32
    8000311a:	84aa                	mv	s1,a0
    8000311c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	95c080e7          	jalr	-1700(ra) # 80001a7a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003126:	22053783          	ld	a5,544(a0)
    8000312a:	02f4f963          	bgeu	s1,a5,8000315c <fetchaddr+0x4e>
    8000312e:	00848713          	addi	a4,s1,8
    80003132:	02e7e763          	bltu	a5,a4,80003160 <fetchaddr+0x52>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003136:	46a1                	li	a3,8
    80003138:	8626                	mv	a2,s1
    8000313a:	85ca                	mv	a1,s2
    8000313c:	22853503          	ld	a0,552(a0)
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	62e080e7          	jalr	1582(ra) # 8000176e <copyin>
    80003148:	00a03533          	snez	a0,a0
    8000314c:	40a00533          	neg	a0,a0
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6902                	ld	s2,0(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret
    return -1;
    8000315c:	557d                	li	a0,-1
    8000315e:	bfcd                	j	80003150 <fetchaddr+0x42>
    80003160:	557d                	li	a0,-1
    80003162:	b7fd                	j	80003150 <fetchaddr+0x42>

0000000080003164 <fetchstr>:
{
    80003164:	7179                	addi	sp,sp,-48
    80003166:	f406                	sd	ra,40(sp)
    80003168:	f022                	sd	s0,32(sp)
    8000316a:	ec26                	sd	s1,24(sp)
    8000316c:	e84a                	sd	s2,16(sp)
    8000316e:	e44e                	sd	s3,8(sp)
    80003170:	1800                	addi	s0,sp,48
    80003172:	892a                	mv	s2,a0
    80003174:	84ae                	mv	s1,a1
    80003176:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003178:	fffff097          	auipc	ra,0xfffff
    8000317c:	902080e7          	jalr	-1790(ra) # 80001a7a <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003180:	86ce                	mv	a3,s3
    80003182:	864a                	mv	a2,s2
    80003184:	85a6                	mv	a1,s1
    80003186:	22853503          	ld	a0,552(a0)
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	672080e7          	jalr	1650(ra) # 800017fc <copyinstr>
    80003192:	00054e63          	bltz	a0,800031ae <fetchstr+0x4a>
  return strlen(buf);
    80003196:	8526                	mv	a0,s1
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	d10080e7          	jalr	-752(ra) # 80000ea8 <strlen>
}
    800031a0:	70a2                	ld	ra,40(sp)
    800031a2:	7402                	ld	s0,32(sp)
    800031a4:	64e2                	ld	s1,24(sp)
    800031a6:	6942                	ld	s2,16(sp)
    800031a8:	69a2                	ld	s3,8(sp)
    800031aa:	6145                	addi	sp,sp,48
    800031ac:	8082                	ret
    return -1;
    800031ae:	557d                	li	a0,-1
    800031b0:	bfc5                	j	800031a0 <fetchstr+0x3c>

00000000800031b2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	1000                	addi	s0,sp,32
    800031bc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	edc080e7          	jalr	-292(ra) # 8000309a <argraw>
    800031c6:	c088                	sw	a0,0(s1)
}
    800031c8:	60e2                	ld	ra,24(sp)
    800031ca:	6442                	ld	s0,16(sp)
    800031cc:	64a2                	ld	s1,8(sp)
    800031ce:	6105                	addi	sp,sp,32
    800031d0:	8082                	ret

00000000800031d2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800031d2:	1101                	addi	sp,sp,-32
    800031d4:	ec06                	sd	ra,24(sp)
    800031d6:	e822                	sd	s0,16(sp)
    800031d8:	e426                	sd	s1,8(sp)
    800031da:	1000                	addi	s0,sp,32
    800031dc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	ebc080e7          	jalr	-324(ra) # 8000309a <argraw>
    800031e6:	e088                	sd	a0,0(s1)
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6105                	addi	sp,sp,32
    800031f0:	8082                	ret

00000000800031f2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031f2:	7179                	addi	sp,sp,-48
    800031f4:	f406                	sd	ra,40(sp)
    800031f6:	f022                	sd	s0,32(sp)
    800031f8:	ec26                	sd	s1,24(sp)
    800031fa:	e84a                	sd	s2,16(sp)
    800031fc:	1800                	addi	s0,sp,48
    800031fe:	84ae                	mv	s1,a1
    80003200:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003202:	fd840593          	addi	a1,s0,-40
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	fcc080e7          	jalr	-52(ra) # 800031d2 <argaddr>
  return fetchstr(addr, buf, max);
    8000320e:	864a                	mv	a2,s2
    80003210:	85a6                	mv	a1,s1
    80003212:	fd843503          	ld	a0,-40(s0)
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	f4e080e7          	jalr	-178(ra) # 80003164 <fetchstr>
}
    8000321e:	70a2                	ld	ra,40(sp)
    80003220:	7402                	ld	s0,32(sp)
    80003222:	64e2                	ld	s1,24(sp)
    80003224:	6942                	ld	s2,16(sp)
    80003226:	6145                	addi	sp,sp,48
    80003228:	8082                	ret

000000008000322a <syscall>:
    [SYS_settickets] sys_settickets,
};

void
syscall(void)
{
    8000322a:	7179                	addi	sp,sp,-48
    8000322c:	f406                	sd	ra,40(sp)
    8000322e:	f022                	sd	s0,32(sp)
    80003230:	ec26                	sd	s1,24(sp)
    80003232:	e84a                	sd	s2,16(sp)
    80003234:	e44e                	sd	s3,8(sp)
    80003236:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80003238:	fffff097          	auipc	ra,0xfffff
    8000323c:	842080e7          	jalr	-1982(ra) # 80001a7a <myproc>
    80003240:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003242:	23053983          	ld	s3,560(a0)
    80003246:	0a89b783          	ld	a5,168(s3)
    8000324a:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000324e:	37fd                	addiw	a5,a5,-1
    80003250:	4765                	li	a4,25
    80003252:	02f76663          	bltu	a4,a5,8000327e <syscall+0x54>
    80003256:	00391713          	slli	a4,s2,0x3
    8000325a:	00005797          	auipc	a5,0x5
    8000325e:	52e78793          	addi	a5,a5,1326 # 80008788 <syscalls>
    80003262:	97ba                	add	a5,a5,a4
    80003264:	639c                	ld	a5,0(a5)
    80003266:	cf81                	beqz	a5,8000327e <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003268:	9782                	jalr	a5
    8000326a:	06a9b823          	sd	a0,112(s3)
    p->syscall_count[num]++;
    8000326e:	090a                	slli	s2,s2,0x2
    80003270:	9926                	add	s2,s2,s1
    80003272:	04092783          	lw	a5,64(s2)
    80003276:	2785                	addiw	a5,a5,1
    80003278:	04f92023          	sw	a5,64(s2)
    8000327c:	a00d                	j	8000329e <syscall+0x74>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000327e:	86ca                	mv	a3,s2
    80003280:	33048613          	addi	a2,s1,816
    80003284:	588c                	lw	a1,48(s1)
    80003286:	00005517          	auipc	a0,0x5
    8000328a:	14250513          	addi	a0,a0,322 # 800083c8 <etext+0x3c8>
    8000328e:	ffffd097          	auipc	ra,0xffffd
    80003292:	31c080e7          	jalr	796(ra) # 800005aa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003296:	2304b783          	ld	a5,560(s1)
    8000329a:	577d                	li	a4,-1
    8000329c:	fbb8                	sd	a4,112(a5)
  }
}
    8000329e:	70a2                	ld	ra,40(sp)
    800032a0:	7402                	ld	s0,32(sp)
    800032a2:	64e2                	ld	s1,24(sp)
    800032a4:	6942                	ld	s2,16(sp)
    800032a6:	69a2                	ld	s3,8(sp)
    800032a8:	6145                	addi	sp,sp,48
    800032aa:	8082                	ret

00000000800032ac <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032b4:	fec40593          	addi	a1,s0,-20
    800032b8:	4501                	li	a0,0
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	ef8080e7          	jalr	-264(ra) # 800031b2 <argint>
  exit(n);
    800032c2:	fec42503          	lw	a0,-20(s0)
    800032c6:	fffff097          	auipc	ra,0xfffff
    800032ca:	352080e7          	jalr	850(ra) # 80002618 <exit>
  return 0; // not reached
}
    800032ce:	4501                	li	a0,0
    800032d0:	60e2                	ld	ra,24(sp)
    800032d2:	6442                	ld	s0,16(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032d8:	1141                	addi	sp,sp,-16
    800032da:	e406                	sd	ra,8(sp)
    800032dc:	e022                	sd	s0,0(sp)
    800032de:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	79a080e7          	jalr	1946(ra) # 80001a7a <myproc>
}
    800032e8:	5908                	lw	a0,48(a0)
    800032ea:	60a2                	ld	ra,8(sp)
    800032ec:	6402                	ld	s0,0(sp)
    800032ee:	0141                	addi	sp,sp,16
    800032f0:	8082                	ret

00000000800032f2 <sys_fork>:

uint64
sys_fork(void)
{
    800032f2:	1141                	addi	sp,sp,-16
    800032f4:	e406                	sd	ra,8(sp)
    800032f6:	e022                	sd	s0,0(sp)
    800032f8:	0800                	addi	s0,sp,16
  return fork();
    800032fa:	fffff097          	auipc	ra,0xfffff
    800032fe:	ba2080e7          	jalr	-1118(ra) # 80001e9c <fork>
}
    80003302:	60a2                	ld	ra,8(sp)
    80003304:	6402                	ld	s0,0(sp)
    80003306:	0141                	addi	sp,sp,16
    80003308:	8082                	ret

000000008000330a <sys_wait>:

uint64
sys_wait(void)
{
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003312:	fe840593          	addi	a1,s0,-24
    80003316:	4501                	li	a0,0
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	eba080e7          	jalr	-326(ra) # 800031d2 <argaddr>
  return wait(p);
    80003320:	fe843503          	ld	a0,-24(s0)
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	4a6080e7          	jalr	1190(ra) # 800027ca <wait>
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret

0000000080003334 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003334:	7179                	addi	sp,sp,-48
    80003336:	f406                	sd	ra,40(sp)
    80003338:	f022                	sd	s0,32(sp)
    8000333a:	ec26                	sd	s1,24(sp)
    8000333c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000333e:	fdc40593          	addi	a1,s0,-36
    80003342:	4501                	li	a0,0
    80003344:	00000097          	auipc	ra,0x0
    80003348:	e6e080e7          	jalr	-402(ra) # 800031b2 <argint>
  addr = myproc()->sz;
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	72e080e7          	jalr	1838(ra) # 80001a7a <myproc>
    80003354:	22053483          	ld	s1,544(a0)
  if (growproc(n) < 0)
    80003358:	fdc42503          	lw	a0,-36(s0)
    8000335c:	fffff097          	auipc	ra,0xfffff
    80003360:	adc080e7          	jalr	-1316(ra) # 80001e38 <growproc>
    80003364:	00054863          	bltz	a0,80003374 <sys_sbrk+0x40>
    return -1;
  return addr;
}
    80003368:	8526                	mv	a0,s1
    8000336a:	70a2                	ld	ra,40(sp)
    8000336c:	7402                	ld	s0,32(sp)
    8000336e:	64e2                	ld	s1,24(sp)
    80003370:	6145                	addi	sp,sp,48
    80003372:	8082                	ret
    return -1;
    80003374:	54fd                	li	s1,-1
    80003376:	bfcd                	j	80003368 <sys_sbrk+0x34>

0000000080003378 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003378:	7139                	addi	sp,sp,-64
    8000337a:	fc06                	sd	ra,56(sp)
    8000337c:	f822                	sd	s0,48(sp)
    8000337e:	f04a                	sd	s2,32(sp)
    80003380:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003382:	fcc40593          	addi	a1,s0,-52
    80003386:	4501                	li	a0,0
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	e2a080e7          	jalr	-470(ra) # 800031b2 <argint>
  acquire(&tickslock);
    80003390:	0001e517          	auipc	a0,0x1e
    80003394:	31050513          	addi	a0,a0,784 # 800216a0 <tickslock>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	8a0080e7          	jalr	-1888(ra) # 80000c38 <acquire>
  ticks0 = ticks;
    800033a0:	00008917          	auipc	s2,0x8
    800033a4:	05492903          	lw	s2,84(s2) # 8000b3f4 <ticks>
  while (ticks - ticks0 < n)
    800033a8:	fcc42783          	lw	a5,-52(s0)
    800033ac:	c3b9                	beqz	a5,800033f2 <sys_sleep+0x7a>
    800033ae:	f426                	sd	s1,40(sp)
    800033b0:	ec4e                	sd	s3,24(sp)
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033b2:	0001e997          	auipc	s3,0x1e
    800033b6:	2ee98993          	addi	s3,s3,750 # 800216a0 <tickslock>
    800033ba:	00008497          	auipc	s1,0x8
    800033be:	03a48493          	addi	s1,s1,58 # 8000b3f4 <ticks>
    if (killed(myproc()))
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	6b8080e7          	jalr	1720(ra) # 80001a7a <myproc>
    800033ca:	fffff097          	auipc	ra,0xfffff
    800033ce:	3ce080e7          	jalr	974(ra) # 80002798 <killed>
    800033d2:	ed15                	bnez	a0,8000340e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800033d4:	85ce                	mv	a1,s3
    800033d6:	8526                	mv	a0,s1
    800033d8:	fffff097          	auipc	ra,0xfffff
    800033dc:	10c080e7          	jalr	268(ra) # 800024e4 <sleep>
  while (ticks - ticks0 < n)
    800033e0:	409c                	lw	a5,0(s1)
    800033e2:	412787bb          	subw	a5,a5,s2
    800033e6:	fcc42703          	lw	a4,-52(s0)
    800033ea:	fce7ece3          	bltu	a5,a4,800033c2 <sys_sleep+0x4a>
    800033ee:	74a2                	ld	s1,40(sp)
    800033f0:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    800033f2:	0001e517          	auipc	a0,0x1e
    800033f6:	2ae50513          	addi	a0,a0,686 # 800216a0 <tickslock>
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	8f2080e7          	jalr	-1806(ra) # 80000cec <release>
  return 0;
    80003402:	4501                	li	a0,0
}
    80003404:	70e2                	ld	ra,56(sp)
    80003406:	7442                	ld	s0,48(sp)
    80003408:	7902                	ld	s2,32(sp)
    8000340a:	6121                	addi	sp,sp,64
    8000340c:	8082                	ret
      release(&tickslock);
    8000340e:	0001e517          	auipc	a0,0x1e
    80003412:	29250513          	addi	a0,a0,658 # 800216a0 <tickslock>
    80003416:	ffffe097          	auipc	ra,0xffffe
    8000341a:	8d6080e7          	jalr	-1834(ra) # 80000cec <release>
      return -1;
    8000341e:	557d                	li	a0,-1
    80003420:	74a2                	ld	s1,40(sp)
    80003422:	69e2                	ld	s3,24(sp)
    80003424:	b7c5                	j	80003404 <sys_sleep+0x8c>

0000000080003426 <sys_kill>:

uint64
sys_kill(void)
{
    80003426:	1101                	addi	sp,sp,-32
    80003428:	ec06                	sd	ra,24(sp)
    8000342a:	e822                	sd	s0,16(sp)
    8000342c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000342e:	fec40593          	addi	a1,s0,-20
    80003432:	4501                	li	a0,0
    80003434:	00000097          	auipc	ra,0x0
    80003438:	d7e080e7          	jalr	-642(ra) # 800031b2 <argint>
  return kill(pid);
    8000343c:	fec42503          	lw	a0,-20(s0)
    80003440:	fffff097          	auipc	ra,0xfffff
    80003444:	2ba080e7          	jalr	698(ra) # 800026fa <kill>
}
    80003448:	60e2                	ld	ra,24(sp)
    8000344a:	6442                	ld	s0,16(sp)
    8000344c:	6105                	addi	sp,sp,32
    8000344e:	8082                	ret

0000000080003450 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003450:	1101                	addi	sp,sp,-32
    80003452:	ec06                	sd	ra,24(sp)
    80003454:	e822                	sd	s0,16(sp)
    80003456:	e426                	sd	s1,8(sp)
    80003458:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000345a:	0001e517          	auipc	a0,0x1e
    8000345e:	24650513          	addi	a0,a0,582 # 800216a0 <tickslock>
    80003462:	ffffd097          	auipc	ra,0xffffd
    80003466:	7d6080e7          	jalr	2006(ra) # 80000c38 <acquire>
  xticks = ticks;
    8000346a:	00008497          	auipc	s1,0x8
    8000346e:	f8a4a483          	lw	s1,-118(s1) # 8000b3f4 <ticks>
  release(&tickslock);
    80003472:	0001e517          	auipc	a0,0x1e
    80003476:	22e50513          	addi	a0,a0,558 # 800216a0 <tickslock>
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	872080e7          	jalr	-1934(ra) # 80000cec <release>
  return xticks;
}
    80003482:	02049513          	slli	a0,s1,0x20
    80003486:	9101                	srli	a0,a0,0x20
    80003488:	60e2                	ld	ra,24(sp)
    8000348a:	6442                	ld	s0,16(sp)
    8000348c:	64a2                	ld	s1,8(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret

0000000080003492 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003492:	7139                	addi	sp,sp,-64
    80003494:	fc06                	sd	ra,56(sp)
    80003496:	f822                	sd	s0,48(sp)
    80003498:	f426                	sd	s1,40(sp)
    8000349a:	f04a                	sd	s2,32(sp)
    8000349c:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000349e:	fd840593          	addi	a1,s0,-40
    800034a2:	4501                	li	a0,0
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	d2e080e7          	jalr	-722(ra) # 800031d2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800034ac:	fd040593          	addi	a1,s0,-48
    800034b0:	4505                	li	a0,1
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	d20080e7          	jalr	-736(ra) # 800031d2 <argaddr>
  argaddr(2, &addr2);
    800034ba:	fc840593          	addi	a1,s0,-56
    800034be:	4509                	li	a0,2
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	d12080e7          	jalr	-750(ra) # 800031d2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800034c8:	fc040613          	addi	a2,s0,-64
    800034cc:	fc440593          	addi	a1,s0,-60
    800034d0:	fd843503          	ld	a0,-40(s0)
    800034d4:	fffff097          	auipc	ra,0xfffff
    800034d8:	5a4080e7          	jalr	1444(ra) # 80002a78 <waitx>
    800034dc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800034de:	ffffe097          	auipc	ra,0xffffe
    800034e2:	59c080e7          	jalr	1436(ra) # 80001a7a <myproc>
    800034e6:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034e8:	4691                	li	a3,4
    800034ea:	fc440613          	addi	a2,s0,-60
    800034ee:	fd043583          	ld	a1,-48(s0)
    800034f2:	22853503          	ld	a0,552(a0)
    800034f6:	ffffe097          	auipc	ra,0xffffe
    800034fa:	1ec080e7          	jalr	492(ra) # 800016e2 <copyout>
    return -1;
    800034fe:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003500:	02054063          	bltz	a0,80003520 <sys_waitx+0x8e>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003504:	4691                	li	a3,4
    80003506:	fc040613          	addi	a2,s0,-64
    8000350a:	fc843583          	ld	a1,-56(s0)
    8000350e:	2284b503          	ld	a0,552(s1)
    80003512:	ffffe097          	auipc	ra,0xffffe
    80003516:	1d0080e7          	jalr	464(ra) # 800016e2 <copyout>
    8000351a:	00054a63          	bltz	a0,8000352e <sys_waitx+0x9c>
    return -1;
  return ret;
    8000351e:	87ca                	mv	a5,s2
}
    80003520:	853e                	mv	a0,a5
    80003522:	70e2                	ld	ra,56(sp)
    80003524:	7442                	ld	s0,48(sp)
    80003526:	74a2                	ld	s1,40(sp)
    80003528:	7902                	ld	s2,32(sp)
    8000352a:	6121                	addi	sp,sp,64
    8000352c:	8082                	ret
    return -1;
    8000352e:	57fd                	li	a5,-1
    80003530:	bfc5                	j	80003520 <sys_waitx+0x8e>

0000000080003532 <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	1000                	addi	s0,sp,32
  int k;
  argint(0, &k);
    8000353a:	fec40593          	addi	a1,s0,-20
    8000353e:	4501                	li	a0,0
    80003540:	00000097          	auipc	ra,0x0
    80003544:	c72080e7          	jalr	-910(ra) # 800031b2 <argint>
  return myproc()->syscall_count[k];
    80003548:	ffffe097          	auipc	ra,0xffffe
    8000354c:	532080e7          	jalr	1330(ra) # 80001a7a <myproc>
    80003550:	fec42783          	lw	a5,-20(s0)
    80003554:	07c1                	addi	a5,a5,16
    80003556:	078a                	slli	a5,a5,0x2
    80003558:	953e                	add	a0,a0,a5
}
    8000355a:	4108                	lw	a0,0(a0)
    8000355c:	60e2                	ld	ra,24(sp)
    8000355e:	6442                	ld	s0,16(sp)
    80003560:	6105                	addi	sp,sp,32
    80003562:	8082                	ret

0000000080003564 <sys_sigalarm>:

// In sysproc.c
uint64 sys_sigalarm(void)
{
    80003564:	1101                	addi	sp,sp,-32
    80003566:	ec06                	sd	ra,24(sp)
    80003568:	e822                	sd	s0,16(sp)
    8000356a:	1000                	addi	s0,sp,32
  int interval;
  uint64 handler;

  argint(0, &interval);
    8000356c:	fec40593          	addi	a1,s0,-20
    80003570:	4501                	li	a0,0
    80003572:	00000097          	auipc	ra,0x0
    80003576:	c40080e7          	jalr	-960(ra) # 800031b2 <argint>
  if(interval < 0)
    8000357a:	fec42783          	lw	a5,-20(s0)
    return -1;
    8000357e:	557d                	li	a0,-1
  if(interval < 0)
    80003580:	0207c963          	bltz	a5,800035b2 <sys_sigalarm+0x4e>
  
  argaddr(1, &handler);
    80003584:	fe040593          	addi	a1,s0,-32
    80003588:	4505                	li	a0,1
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	c48080e7          	jalr	-952(ra) # 800031d2 <argaddr>
  if(handler < 0)
    return -1;

  struct proc *p = myproc();
    80003592:	ffffe097          	auipc	ra,0xffffe
    80003596:	4e8080e7          	jalr	1256(ra) # 80001a7a <myproc>
  p->interval = interval;
    8000359a:	fec42783          	lw	a5,-20(s0)
    8000359e:	0ef52223          	sw	a5,228(a0)
  p->handler_addr = handler;
    800035a2:	fe043783          	ld	a5,-32(s0)
    800035a6:	f57c                	sd	a5,232(a0)
  p->ticks = 0;
    800035a8:	0e052023          	sw	zero,224(a0)
  p->alarm_set = 0; 
    800035ac:	20052823          	sw	zero,528(a0)

  return 0;
    800035b0:	4501                	li	a0,0
}
    800035b2:	60e2                	ld	ra,24(sp)
    800035b4:	6442                	ld	s0,16(sp)
    800035b6:	6105                	addi	sp,sp,32
    800035b8:	8082                	ret

00000000800035ba <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    800035ba:	1101                	addi	sp,sp,-32
    800035bc:	ec06                	sd	ra,24(sp)
    800035be:	e822                	sd	s0,16(sp)
    800035c0:	e426                	sd	s1,8(sp)
    800035c2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800035c4:	ffffe097          	auipc	ra,0xffffe
    800035c8:	4b6080e7          	jalr	1206(ra) # 80001a7a <myproc>
    800035cc:	84aa                	mv	s1,a0
  memmove(p->trapframe, &p->saved_alarm_tf, sizeof(struct trapframe));
    800035ce:	12000613          	li	a2,288
    800035d2:	0f050593          	addi	a1,a0,240
    800035d6:	23053503          	ld	a0,560(a0)
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	7b6080e7          	jalr	1974(ra) # 80000d90 <memmove>
  p->alarm_set = 0;                                         
    800035e2:	2004a823          	sw	zero,528(s1)
  return (uint64)p->trapframe->a0;
    800035e6:	2304b783          	ld	a5,560(s1)
}
    800035ea:	7ba8                	ld	a0,112(a5)
    800035ec:	60e2                	ld	ra,24(sp)
    800035ee:	6442                	ld	s0,16(sp)
    800035f0:	64a2                	ld	s1,8(sp)
    800035f2:	6105                	addi	sp,sp,32
    800035f4:	8082                	ret

00000000800035f6 <sys_settickets>:

uint64
sys_settickets(void)
{
    800035f6:	1101                	addi	sp,sp,-32
    800035f8:	ec06                	sd	ra,24(sp)
    800035fa:	e822                	sd	s0,16(sp)
    800035fc:	1000                	addi	s0,sp,32
  int number;
  argint(0, &number);
    800035fe:	fec40593          	addi	a1,s0,-20
    80003602:	4501                	li	a0,0
    80003604:	00000097          	auipc	ra,0x0
    80003608:	bae080e7          	jalr	-1106(ra) # 800031b2 <argint>
  if (number < 1)
    8000360c:	fec42783          	lw	a5,-20(s0)
    return -1;
    80003610:	557d                	li	a0,-1
  if (number < 1)
    80003612:	00f05b63          	blez	a5,80003628 <sys_settickets+0x32>
  struct proc *p = myproc();
    80003616:	ffffe097          	auipc	ra,0xffffe
    8000361a:	464080e7          	jalr	1124(ra) # 80001a7a <myproc>
  p->tickets = number;
    8000361e:	fec42783          	lw	a5,-20(s0)
    80003622:	0cf52023          	sw	a5,192(a0)
  return 0;
    80003626:	4501                	li	a0,0
    80003628:	60e2                	ld	ra,24(sp)
    8000362a:	6442                	ld	s0,16(sp)
    8000362c:	6105                	addi	sp,sp,32
    8000362e:	8082                	ret

0000000080003630 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003630:	7179                	addi	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	e052                	sd	s4,0(sp)
    8000363e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003640:	00005597          	auipc	a1,0x5
    80003644:	da858593          	addi	a1,a1,-600 # 800083e8 <etext+0x3e8>
    80003648:	0001e517          	auipc	a0,0x1e
    8000364c:	07050513          	addi	a0,a0,112 # 800216b8 <bcache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	558080e7          	jalr	1368(ra) # 80000ba8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003658:	00026797          	auipc	a5,0x26
    8000365c:	06078793          	addi	a5,a5,96 # 800296b8 <bcache+0x8000>
    80003660:	00026717          	auipc	a4,0x26
    80003664:	2c070713          	addi	a4,a4,704 # 80029920 <bcache+0x8268>
    80003668:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000366c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003670:	0001e497          	auipc	s1,0x1e
    80003674:	06048493          	addi	s1,s1,96 # 800216d0 <bcache+0x18>
    b->next = bcache.head.next;
    80003678:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000367a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000367c:	00005a17          	auipc	s4,0x5
    80003680:	d74a0a13          	addi	s4,s4,-652 # 800083f0 <etext+0x3f0>
    b->next = bcache.head.next;
    80003684:	2b893783          	ld	a5,696(s2)
    80003688:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000368a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000368e:	85d2                	mv	a1,s4
    80003690:	01048513          	addi	a0,s1,16
    80003694:	00001097          	auipc	ra,0x1
    80003698:	4e8080e7          	jalr	1256(ra) # 80004b7c <initsleeplock>
    bcache.head.next->prev = b;
    8000369c:	2b893783          	ld	a5,696(s2)
    800036a0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036a2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036a6:	45848493          	addi	s1,s1,1112
    800036aa:	fd349de3          	bne	s1,s3,80003684 <binit+0x54>
  }
}
    800036ae:	70a2                	ld	ra,40(sp)
    800036b0:	7402                	ld	s0,32(sp)
    800036b2:	64e2                	ld	s1,24(sp)
    800036b4:	6942                	ld	s2,16(sp)
    800036b6:	69a2                	ld	s3,8(sp)
    800036b8:	6a02                	ld	s4,0(sp)
    800036ba:	6145                	addi	sp,sp,48
    800036bc:	8082                	ret

00000000800036be <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036be:	7179                	addi	sp,sp,-48
    800036c0:	f406                	sd	ra,40(sp)
    800036c2:	f022                	sd	s0,32(sp)
    800036c4:	ec26                	sd	s1,24(sp)
    800036c6:	e84a                	sd	s2,16(sp)
    800036c8:	e44e                	sd	s3,8(sp)
    800036ca:	1800                	addi	s0,sp,48
    800036cc:	892a                	mv	s2,a0
    800036ce:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036d0:	0001e517          	auipc	a0,0x1e
    800036d4:	fe850513          	addi	a0,a0,-24 # 800216b8 <bcache>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	560080e7          	jalr	1376(ra) # 80000c38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036e0:	00026497          	auipc	s1,0x26
    800036e4:	2904b483          	ld	s1,656(s1) # 80029970 <bcache+0x82b8>
    800036e8:	00026797          	auipc	a5,0x26
    800036ec:	23878793          	addi	a5,a5,568 # 80029920 <bcache+0x8268>
    800036f0:	02f48f63          	beq	s1,a5,8000372e <bread+0x70>
    800036f4:	873e                	mv	a4,a5
    800036f6:	a021                	j	800036fe <bread+0x40>
    800036f8:	68a4                	ld	s1,80(s1)
    800036fa:	02e48a63          	beq	s1,a4,8000372e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036fe:	449c                	lw	a5,8(s1)
    80003700:	ff279ce3          	bne	a5,s2,800036f8 <bread+0x3a>
    80003704:	44dc                	lw	a5,12(s1)
    80003706:	ff3799e3          	bne	a5,s3,800036f8 <bread+0x3a>
      b->refcnt++;
    8000370a:	40bc                	lw	a5,64(s1)
    8000370c:	2785                	addiw	a5,a5,1
    8000370e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003710:	0001e517          	auipc	a0,0x1e
    80003714:	fa850513          	addi	a0,a0,-88 # 800216b8 <bcache>
    80003718:	ffffd097          	auipc	ra,0xffffd
    8000371c:	5d4080e7          	jalr	1492(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    80003720:	01048513          	addi	a0,s1,16
    80003724:	00001097          	auipc	ra,0x1
    80003728:	492080e7          	jalr	1170(ra) # 80004bb6 <acquiresleep>
      return b;
    8000372c:	a8b9                	j	8000378a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000372e:	00026497          	auipc	s1,0x26
    80003732:	23a4b483          	ld	s1,570(s1) # 80029968 <bcache+0x82b0>
    80003736:	00026797          	auipc	a5,0x26
    8000373a:	1ea78793          	addi	a5,a5,490 # 80029920 <bcache+0x8268>
    8000373e:	00f48863          	beq	s1,a5,8000374e <bread+0x90>
    80003742:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003744:	40bc                	lw	a5,64(s1)
    80003746:	cf81                	beqz	a5,8000375e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003748:	64a4                	ld	s1,72(s1)
    8000374a:	fee49de3          	bne	s1,a4,80003744 <bread+0x86>
  panic("bget: no buffers");
    8000374e:	00005517          	auipc	a0,0x5
    80003752:	caa50513          	addi	a0,a0,-854 # 800083f8 <etext+0x3f8>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	e0a080e7          	jalr	-502(ra) # 80000560 <panic>
      b->dev = dev;
    8000375e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003762:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003766:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000376a:	4785                	li	a5,1
    8000376c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000376e:	0001e517          	auipc	a0,0x1e
    80003772:	f4a50513          	addi	a0,a0,-182 # 800216b8 <bcache>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	576080e7          	jalr	1398(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    8000377e:	01048513          	addi	a0,s1,16
    80003782:	00001097          	auipc	ra,0x1
    80003786:	434080e7          	jalr	1076(ra) # 80004bb6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000378a:	409c                	lw	a5,0(s1)
    8000378c:	cb89                	beqz	a5,8000379e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000378e:	8526                	mv	a0,s1
    80003790:	70a2                	ld	ra,40(sp)
    80003792:	7402                	ld	s0,32(sp)
    80003794:	64e2                	ld	s1,24(sp)
    80003796:	6942                	ld	s2,16(sp)
    80003798:	69a2                	ld	s3,8(sp)
    8000379a:	6145                	addi	sp,sp,48
    8000379c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000379e:	4581                	li	a1,0
    800037a0:	8526                	mv	a0,s1
    800037a2:	00003097          	auipc	ra,0x3
    800037a6:	106080e7          	jalr	262(ra) # 800068a8 <virtio_disk_rw>
    b->valid = 1;
    800037aa:	4785                	li	a5,1
    800037ac:	c09c                	sw	a5,0(s1)
  return b;
    800037ae:	b7c5                	j	8000378e <bread+0xd0>

00000000800037b0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037b0:	1101                	addi	sp,sp,-32
    800037b2:	ec06                	sd	ra,24(sp)
    800037b4:	e822                	sd	s0,16(sp)
    800037b6:	e426                	sd	s1,8(sp)
    800037b8:	1000                	addi	s0,sp,32
    800037ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037bc:	0541                	addi	a0,a0,16
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	492080e7          	jalr	1170(ra) # 80004c50 <holdingsleep>
    800037c6:	cd01                	beqz	a0,800037de <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037c8:	4585                	li	a1,1
    800037ca:	8526                	mv	a0,s1
    800037cc:	00003097          	auipc	ra,0x3
    800037d0:	0dc080e7          	jalr	220(ra) # 800068a8 <virtio_disk_rw>
}
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	64a2                	ld	s1,8(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret
    panic("bwrite");
    800037de:	00005517          	auipc	a0,0x5
    800037e2:	c3250513          	addi	a0,a0,-974 # 80008410 <etext+0x410>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	d7a080e7          	jalr	-646(ra) # 80000560 <panic>

00000000800037ee <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	e04a                	sd	s2,0(sp)
    800037f8:	1000                	addi	s0,sp,32
    800037fa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037fc:	01050913          	addi	s2,a0,16
    80003800:	854a                	mv	a0,s2
    80003802:	00001097          	auipc	ra,0x1
    80003806:	44e080e7          	jalr	1102(ra) # 80004c50 <holdingsleep>
    8000380a:	c925                	beqz	a0,8000387a <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	3fe080e7          	jalr	1022(ra) # 80004c0c <releasesleep>

  acquire(&bcache.lock);
    80003816:	0001e517          	auipc	a0,0x1e
    8000381a:	ea250513          	addi	a0,a0,-350 # 800216b8 <bcache>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	41a080e7          	jalr	1050(ra) # 80000c38 <acquire>
  b->refcnt--;
    80003826:	40bc                	lw	a5,64(s1)
    80003828:	37fd                	addiw	a5,a5,-1
    8000382a:	0007871b          	sext.w	a4,a5
    8000382e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003830:	e71d                	bnez	a4,8000385e <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003832:	68b8                	ld	a4,80(s1)
    80003834:	64bc                	ld	a5,72(s1)
    80003836:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003838:	68b8                	ld	a4,80(s1)
    8000383a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000383c:	00026797          	auipc	a5,0x26
    80003840:	e7c78793          	addi	a5,a5,-388 # 800296b8 <bcache+0x8000>
    80003844:	2b87b703          	ld	a4,696(a5)
    80003848:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000384a:	00026717          	auipc	a4,0x26
    8000384e:	0d670713          	addi	a4,a4,214 # 80029920 <bcache+0x8268>
    80003852:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003854:	2b87b703          	ld	a4,696(a5)
    80003858:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000385a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000385e:	0001e517          	auipc	a0,0x1e
    80003862:	e5a50513          	addi	a0,a0,-422 # 800216b8 <bcache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	486080e7          	jalr	1158(ra) # 80000cec <release>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret
    panic("brelse");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	b9e50513          	addi	a0,a0,-1122 # 80008418 <etext+0x418>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cde080e7          	jalr	-802(ra) # 80000560 <panic>

000000008000388a <bpin>:

void
bpin(struct buf *b) {
    8000388a:	1101                	addi	sp,sp,-32
    8000388c:	ec06                	sd	ra,24(sp)
    8000388e:	e822                	sd	s0,16(sp)
    80003890:	e426                	sd	s1,8(sp)
    80003892:	1000                	addi	s0,sp,32
    80003894:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003896:	0001e517          	auipc	a0,0x1e
    8000389a:	e2250513          	addi	a0,a0,-478 # 800216b8 <bcache>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	39a080e7          	jalr	922(ra) # 80000c38 <acquire>
  b->refcnt++;
    800038a6:	40bc                	lw	a5,64(s1)
    800038a8:	2785                	addiw	a5,a5,1
    800038aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ac:	0001e517          	auipc	a0,0x1e
    800038b0:	e0c50513          	addi	a0,a0,-500 # 800216b8 <bcache>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	438080e7          	jalr	1080(ra) # 80000cec <release>
}
    800038bc:	60e2                	ld	ra,24(sp)
    800038be:	6442                	ld	s0,16(sp)
    800038c0:	64a2                	ld	s1,8(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret

00000000800038c6 <bunpin>:

void
bunpin(struct buf *b) {
    800038c6:	1101                	addi	sp,sp,-32
    800038c8:	ec06                	sd	ra,24(sp)
    800038ca:	e822                	sd	s0,16(sp)
    800038cc:	e426                	sd	s1,8(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d2:	0001e517          	auipc	a0,0x1e
    800038d6:	de650513          	addi	a0,a0,-538 # 800216b8 <bcache>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	35e080e7          	jalr	862(ra) # 80000c38 <acquire>
  b->refcnt--;
    800038e2:	40bc                	lw	a5,64(s1)
    800038e4:	37fd                	addiw	a5,a5,-1
    800038e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038e8:	0001e517          	auipc	a0,0x1e
    800038ec:	dd050513          	addi	a0,a0,-560 # 800216b8 <bcache>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	3fc080e7          	jalr	1020(ra) # 80000cec <release>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
    8000390e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003910:	00d5d59b          	srliw	a1,a1,0xd
    80003914:	00026797          	auipc	a5,0x26
    80003918:	4807a783          	lw	a5,1152(a5) # 80029d94 <sb+0x1c>
    8000391c:	9dbd                	addw	a1,a1,a5
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	da0080e7          	jalr	-608(ra) # 800036be <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003926:	0074f713          	andi	a4,s1,7
    8000392a:	4785                	li	a5,1
    8000392c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003930:	14ce                	slli	s1,s1,0x33
    80003932:	90d9                	srli	s1,s1,0x36
    80003934:	00950733          	add	a4,a0,s1
    80003938:	05874703          	lbu	a4,88(a4)
    8000393c:	00e7f6b3          	and	a3,a5,a4
    80003940:	c69d                	beqz	a3,8000396e <bfree+0x6c>
    80003942:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003944:	94aa                	add	s1,s1,a0
    80003946:	fff7c793          	not	a5,a5
    8000394a:	8f7d                	and	a4,a4,a5
    8000394c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003950:	00001097          	auipc	ra,0x1
    80003954:	148080e7          	jalr	328(ra) # 80004a98 <log_write>
  brelse(bp);
    80003958:	854a                	mv	a0,s2
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	e94080e7          	jalr	-364(ra) # 800037ee <brelse>
}
    80003962:	60e2                	ld	ra,24(sp)
    80003964:	6442                	ld	s0,16(sp)
    80003966:	64a2                	ld	s1,8(sp)
    80003968:	6902                	ld	s2,0(sp)
    8000396a:	6105                	addi	sp,sp,32
    8000396c:	8082                	ret
    panic("freeing free block");
    8000396e:	00005517          	auipc	a0,0x5
    80003972:	ab250513          	addi	a0,a0,-1358 # 80008420 <etext+0x420>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	bea080e7          	jalr	-1046(ra) # 80000560 <panic>

000000008000397e <balloc>:
{
    8000397e:	711d                	addi	sp,sp,-96
    80003980:	ec86                	sd	ra,88(sp)
    80003982:	e8a2                	sd	s0,80(sp)
    80003984:	e4a6                	sd	s1,72(sp)
    80003986:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003988:	00026797          	auipc	a5,0x26
    8000398c:	3f47a783          	lw	a5,1012(a5) # 80029d7c <sb+0x4>
    80003990:	10078f63          	beqz	a5,80003aae <balloc+0x130>
    80003994:	e0ca                	sd	s2,64(sp)
    80003996:	fc4e                	sd	s3,56(sp)
    80003998:	f852                	sd	s4,48(sp)
    8000399a:	f456                	sd	s5,40(sp)
    8000399c:	f05a                	sd	s6,32(sp)
    8000399e:	ec5e                	sd	s7,24(sp)
    800039a0:	e862                	sd	s8,16(sp)
    800039a2:	e466                	sd	s9,8(sp)
    800039a4:	8baa                	mv	s7,a0
    800039a6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039a8:	00026b17          	auipc	s6,0x26
    800039ac:	3d0b0b13          	addi	s6,s6,976 # 80029d78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039b2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039b6:	6c89                	lui	s9,0x2
    800039b8:	a061                	j	80003a40 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039ba:	97ca                	add	a5,a5,s2
    800039bc:	8e55                	or	a2,a2,a3
    800039be:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	0d4080e7          	jalr	212(ra) # 80004a98 <log_write>
        brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	e20080e7          	jalr	-480(ra) # 800037ee <brelse>
  bp = bread(dev, bno);
    800039d6:	85a6                	mv	a1,s1
    800039d8:	855e                	mv	a0,s7
    800039da:	00000097          	auipc	ra,0x0
    800039de:	ce4080e7          	jalr	-796(ra) # 800036be <bread>
    800039e2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039e4:	40000613          	li	a2,1024
    800039e8:	4581                	li	a1,0
    800039ea:	05850513          	addi	a0,a0,88
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	346080e7          	jalr	838(ra) # 80000d34 <memset>
  log_write(bp);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	0a0080e7          	jalr	160(ra) # 80004a98 <log_write>
  brelse(bp);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	dec080e7          	jalr	-532(ra) # 800037ee <brelse>
}
    80003a0a:	6906                	ld	s2,64(sp)
    80003a0c:	79e2                	ld	s3,56(sp)
    80003a0e:	7a42                	ld	s4,48(sp)
    80003a10:	7aa2                	ld	s5,40(sp)
    80003a12:	7b02                	ld	s6,32(sp)
    80003a14:	6be2                	ld	s7,24(sp)
    80003a16:	6c42                	ld	s8,16(sp)
    80003a18:	6ca2                	ld	s9,8(sp)
}
    80003a1a:	8526                	mv	a0,s1
    80003a1c:	60e6                	ld	ra,88(sp)
    80003a1e:	6446                	ld	s0,80(sp)
    80003a20:	64a6                	ld	s1,72(sp)
    80003a22:	6125                	addi	sp,sp,96
    80003a24:	8082                	ret
    brelse(bp);
    80003a26:	854a                	mv	a0,s2
    80003a28:	00000097          	auipc	ra,0x0
    80003a2c:	dc6080e7          	jalr	-570(ra) # 800037ee <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a30:	015c87bb          	addw	a5,s9,s5
    80003a34:	00078a9b          	sext.w	s5,a5
    80003a38:	004b2703          	lw	a4,4(s6)
    80003a3c:	06eaf163          	bgeu	s5,a4,80003a9e <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    80003a40:	41fad79b          	sraiw	a5,s5,0x1f
    80003a44:	0137d79b          	srliw	a5,a5,0x13
    80003a48:	015787bb          	addw	a5,a5,s5
    80003a4c:	40d7d79b          	sraiw	a5,a5,0xd
    80003a50:	01cb2583          	lw	a1,28(s6)
    80003a54:	9dbd                	addw	a1,a1,a5
    80003a56:	855e                	mv	a0,s7
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	c66080e7          	jalr	-922(ra) # 800036be <bread>
    80003a60:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a62:	004b2503          	lw	a0,4(s6)
    80003a66:	000a849b          	sext.w	s1,s5
    80003a6a:	8762                	mv	a4,s8
    80003a6c:	faa4fde3          	bgeu	s1,a0,80003a26 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003a70:	00777693          	andi	a3,a4,7
    80003a74:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a78:	41f7579b          	sraiw	a5,a4,0x1f
    80003a7c:	01d7d79b          	srliw	a5,a5,0x1d
    80003a80:	9fb9                	addw	a5,a5,a4
    80003a82:	4037d79b          	sraiw	a5,a5,0x3
    80003a86:	00f90633          	add	a2,s2,a5
    80003a8a:	05864603          	lbu	a2,88(a2)
    80003a8e:	00c6f5b3          	and	a1,a3,a2
    80003a92:	d585                	beqz	a1,800039ba <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a94:	2705                	addiw	a4,a4,1
    80003a96:	2485                	addiw	s1,s1,1
    80003a98:	fd471ae3          	bne	a4,s4,80003a6c <balloc+0xee>
    80003a9c:	b769                	j	80003a26 <balloc+0xa8>
    80003a9e:	6906                	ld	s2,64(sp)
    80003aa0:	79e2                	ld	s3,56(sp)
    80003aa2:	7a42                	ld	s4,48(sp)
    80003aa4:	7aa2                	ld	s5,40(sp)
    80003aa6:	7b02                	ld	s6,32(sp)
    80003aa8:	6be2                	ld	s7,24(sp)
    80003aaa:	6c42                	ld	s8,16(sp)
    80003aac:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003aae:	00005517          	auipc	a0,0x5
    80003ab2:	98a50513          	addi	a0,a0,-1654 # 80008438 <etext+0x438>
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	af4080e7          	jalr	-1292(ra) # 800005aa <printf>
  return 0;
    80003abe:	4481                	li	s1,0
    80003ac0:	bfa9                	j	80003a1a <balloc+0x9c>

0000000080003ac2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ac2:	7179                	addi	sp,sp,-48
    80003ac4:	f406                	sd	ra,40(sp)
    80003ac6:	f022                	sd	s0,32(sp)
    80003ac8:	ec26                	sd	s1,24(sp)
    80003aca:	e84a                	sd	s2,16(sp)
    80003acc:	e44e                	sd	s3,8(sp)
    80003ace:	1800                	addi	s0,sp,48
    80003ad0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ad2:	47ad                	li	a5,11
    80003ad4:	02b7e863          	bltu	a5,a1,80003b04 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003ad8:	02059793          	slli	a5,a1,0x20
    80003adc:	01e7d593          	srli	a1,a5,0x1e
    80003ae0:	00b504b3          	add	s1,a0,a1
    80003ae4:	0504a903          	lw	s2,80(s1)
    80003ae8:	08091263          	bnez	s2,80003b6c <bmap+0xaa>
      addr = balloc(ip->dev);
    80003aec:	4108                	lw	a0,0(a0)
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	e90080e7          	jalr	-368(ra) # 8000397e <balloc>
    80003af6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003afa:	06090963          	beqz	s2,80003b6c <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    80003afe:	0524a823          	sw	s2,80(s1)
    80003b02:	a0ad                	j	80003b6c <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003b04:	ff45849b          	addiw	s1,a1,-12
    80003b08:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b0c:	0ff00793          	li	a5,255
    80003b10:	08e7e863          	bltu	a5,a4,80003ba0 <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b14:	08052903          	lw	s2,128(a0)
    80003b18:	00091f63          	bnez	s2,80003b36 <bmap+0x74>
      addr = balloc(ip->dev);
    80003b1c:	4108                	lw	a0,0(a0)
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	e60080e7          	jalr	-416(ra) # 8000397e <balloc>
    80003b26:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b2a:	04090163          	beqz	s2,80003b6c <bmap+0xaa>
    80003b2e:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b30:	0929a023          	sw	s2,128(s3)
    80003b34:	a011                	j	80003b38 <bmap+0x76>
    80003b36:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003b38:	85ca                	mv	a1,s2
    80003b3a:	0009a503          	lw	a0,0(s3)
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	b80080e7          	jalr	-1152(ra) # 800036be <bread>
    80003b46:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b48:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b4c:	02049713          	slli	a4,s1,0x20
    80003b50:	01e75593          	srli	a1,a4,0x1e
    80003b54:	00b784b3          	add	s1,a5,a1
    80003b58:	0004a903          	lw	s2,0(s1)
    80003b5c:	02090063          	beqz	s2,80003b7c <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b60:	8552                	mv	a0,s4
    80003b62:	00000097          	auipc	ra,0x0
    80003b66:	c8c080e7          	jalr	-884(ra) # 800037ee <brelse>
    return addr;
    80003b6a:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	70a2                	ld	ra,40(sp)
    80003b70:	7402                	ld	s0,32(sp)
    80003b72:	64e2                	ld	s1,24(sp)
    80003b74:	6942                	ld	s2,16(sp)
    80003b76:	69a2                	ld	s3,8(sp)
    80003b78:	6145                	addi	sp,sp,48
    80003b7a:	8082                	ret
      addr = balloc(ip->dev);
    80003b7c:	0009a503          	lw	a0,0(s3)
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	dfe080e7          	jalr	-514(ra) # 8000397e <balloc>
    80003b88:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b8c:	fc090ae3          	beqz	s2,80003b60 <bmap+0x9e>
        a[bn] = addr;
    80003b90:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b94:	8552                	mv	a0,s4
    80003b96:	00001097          	auipc	ra,0x1
    80003b9a:	f02080e7          	jalr	-254(ra) # 80004a98 <log_write>
    80003b9e:	b7c9                	j	80003b60 <bmap+0x9e>
    80003ba0:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003ba2:	00005517          	auipc	a0,0x5
    80003ba6:	8ae50513          	addi	a0,a0,-1874 # 80008450 <etext+0x450>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	9b6080e7          	jalr	-1610(ra) # 80000560 <panic>

0000000080003bb2 <iget>:
{
    80003bb2:	7179                	addi	sp,sp,-48
    80003bb4:	f406                	sd	ra,40(sp)
    80003bb6:	f022                	sd	s0,32(sp)
    80003bb8:	ec26                	sd	s1,24(sp)
    80003bba:	e84a                	sd	s2,16(sp)
    80003bbc:	e44e                	sd	s3,8(sp)
    80003bbe:	e052                	sd	s4,0(sp)
    80003bc0:	1800                	addi	s0,sp,48
    80003bc2:	89aa                	mv	s3,a0
    80003bc4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bc6:	00026517          	auipc	a0,0x26
    80003bca:	1d250513          	addi	a0,a0,466 # 80029d98 <itable>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	06a080e7          	jalr	106(ra) # 80000c38 <acquire>
  empty = 0;
    80003bd6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bd8:	00026497          	auipc	s1,0x26
    80003bdc:	1d848493          	addi	s1,s1,472 # 80029db0 <itable+0x18>
    80003be0:	00028697          	auipc	a3,0x28
    80003be4:	c6068693          	addi	a3,a3,-928 # 8002b840 <log>
    80003be8:	a039                	j	80003bf6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bea:	02090b63          	beqz	s2,80003c20 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bee:	08848493          	addi	s1,s1,136
    80003bf2:	02d48a63          	beq	s1,a3,80003c26 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bf6:	449c                	lw	a5,8(s1)
    80003bf8:	fef059e3          	blez	a5,80003bea <iget+0x38>
    80003bfc:	4098                	lw	a4,0(s1)
    80003bfe:	ff3716e3          	bne	a4,s3,80003bea <iget+0x38>
    80003c02:	40d8                	lw	a4,4(s1)
    80003c04:	ff4713e3          	bne	a4,s4,80003bea <iget+0x38>
      ip->ref++;
    80003c08:	2785                	addiw	a5,a5,1
    80003c0a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c0c:	00026517          	auipc	a0,0x26
    80003c10:	18c50513          	addi	a0,a0,396 # 80029d98 <itable>
    80003c14:	ffffd097          	auipc	ra,0xffffd
    80003c18:	0d8080e7          	jalr	216(ra) # 80000cec <release>
      return ip;
    80003c1c:	8926                	mv	s2,s1
    80003c1e:	a03d                	j	80003c4c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c20:	f7f9                	bnez	a5,80003bee <iget+0x3c>
      empty = ip;
    80003c22:	8926                	mv	s2,s1
    80003c24:	b7e9                	j	80003bee <iget+0x3c>
  if(empty == 0)
    80003c26:	02090c63          	beqz	s2,80003c5e <iget+0xac>
  ip->dev = dev;
    80003c2a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c2e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c32:	4785                	li	a5,1
    80003c34:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c38:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c3c:	00026517          	auipc	a0,0x26
    80003c40:	15c50513          	addi	a0,a0,348 # 80029d98 <itable>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	0a8080e7          	jalr	168(ra) # 80000cec <release>
}
    80003c4c:	854a                	mv	a0,s2
    80003c4e:	70a2                	ld	ra,40(sp)
    80003c50:	7402                	ld	s0,32(sp)
    80003c52:	64e2                	ld	s1,24(sp)
    80003c54:	6942                	ld	s2,16(sp)
    80003c56:	69a2                	ld	s3,8(sp)
    80003c58:	6a02                	ld	s4,0(sp)
    80003c5a:	6145                	addi	sp,sp,48
    80003c5c:	8082                	ret
    panic("iget: no inodes");
    80003c5e:	00005517          	auipc	a0,0x5
    80003c62:	80a50513          	addi	a0,a0,-2038 # 80008468 <etext+0x468>
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	8fa080e7          	jalr	-1798(ra) # 80000560 <panic>

0000000080003c6e <fsinit>:
fsinit(int dev) {
    80003c6e:	7179                	addi	sp,sp,-48
    80003c70:	f406                	sd	ra,40(sp)
    80003c72:	f022                	sd	s0,32(sp)
    80003c74:	ec26                	sd	s1,24(sp)
    80003c76:	e84a                	sd	s2,16(sp)
    80003c78:	e44e                	sd	s3,8(sp)
    80003c7a:	1800                	addi	s0,sp,48
    80003c7c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c7e:	4585                	li	a1,1
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	a3e080e7          	jalr	-1474(ra) # 800036be <bread>
    80003c88:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c8a:	00026997          	auipc	s3,0x26
    80003c8e:	0ee98993          	addi	s3,s3,238 # 80029d78 <sb>
    80003c92:	02000613          	li	a2,32
    80003c96:	05850593          	addi	a1,a0,88
    80003c9a:	854e                	mv	a0,s3
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	0f4080e7          	jalr	244(ra) # 80000d90 <memmove>
  brelse(bp);
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	b48080e7          	jalr	-1208(ra) # 800037ee <brelse>
  if(sb.magic != FSMAGIC)
    80003cae:	0009a703          	lw	a4,0(s3)
    80003cb2:	102037b7          	lui	a5,0x10203
    80003cb6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cba:	02f71263          	bne	a4,a5,80003cde <fsinit+0x70>
  initlog(dev, &sb);
    80003cbe:	00026597          	auipc	a1,0x26
    80003cc2:	0ba58593          	addi	a1,a1,186 # 80029d78 <sb>
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	b60080e7          	jalr	-1184(ra) # 80004828 <initlog>
}
    80003cd0:	70a2                	ld	ra,40(sp)
    80003cd2:	7402                	ld	s0,32(sp)
    80003cd4:	64e2                	ld	s1,24(sp)
    80003cd6:	6942                	ld	s2,16(sp)
    80003cd8:	69a2                	ld	s3,8(sp)
    80003cda:	6145                	addi	sp,sp,48
    80003cdc:	8082                	ret
    panic("invalid file system");
    80003cde:	00004517          	auipc	a0,0x4
    80003ce2:	79a50513          	addi	a0,a0,1946 # 80008478 <etext+0x478>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	87a080e7          	jalr	-1926(ra) # 80000560 <panic>

0000000080003cee <iinit>:
{
    80003cee:	7179                	addi	sp,sp,-48
    80003cf0:	f406                	sd	ra,40(sp)
    80003cf2:	f022                	sd	s0,32(sp)
    80003cf4:	ec26                	sd	s1,24(sp)
    80003cf6:	e84a                	sd	s2,16(sp)
    80003cf8:	e44e                	sd	s3,8(sp)
    80003cfa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cfc:	00004597          	auipc	a1,0x4
    80003d00:	79458593          	addi	a1,a1,1940 # 80008490 <etext+0x490>
    80003d04:	00026517          	auipc	a0,0x26
    80003d08:	09450513          	addi	a0,a0,148 # 80029d98 <itable>
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	e9c080e7          	jalr	-356(ra) # 80000ba8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d14:	00026497          	auipc	s1,0x26
    80003d18:	0ac48493          	addi	s1,s1,172 # 80029dc0 <itable+0x28>
    80003d1c:	00028997          	auipc	s3,0x28
    80003d20:	b3498993          	addi	s3,s3,-1228 # 8002b850 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d24:	00004917          	auipc	s2,0x4
    80003d28:	77490913          	addi	s2,s2,1908 # 80008498 <etext+0x498>
    80003d2c:	85ca                	mv	a1,s2
    80003d2e:	8526                	mv	a0,s1
    80003d30:	00001097          	auipc	ra,0x1
    80003d34:	e4c080e7          	jalr	-436(ra) # 80004b7c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d38:	08848493          	addi	s1,s1,136
    80003d3c:	ff3498e3          	bne	s1,s3,80003d2c <iinit+0x3e>
}
    80003d40:	70a2                	ld	ra,40(sp)
    80003d42:	7402                	ld	s0,32(sp)
    80003d44:	64e2                	ld	s1,24(sp)
    80003d46:	6942                	ld	s2,16(sp)
    80003d48:	69a2                	ld	s3,8(sp)
    80003d4a:	6145                	addi	sp,sp,48
    80003d4c:	8082                	ret

0000000080003d4e <ialloc>:
{
    80003d4e:	7139                	addi	sp,sp,-64
    80003d50:	fc06                	sd	ra,56(sp)
    80003d52:	f822                	sd	s0,48(sp)
    80003d54:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d56:	00026717          	auipc	a4,0x26
    80003d5a:	02e72703          	lw	a4,46(a4) # 80029d84 <sb+0xc>
    80003d5e:	4785                	li	a5,1
    80003d60:	06e7f463          	bgeu	a5,a4,80003dc8 <ialloc+0x7a>
    80003d64:	f426                	sd	s1,40(sp)
    80003d66:	f04a                	sd	s2,32(sp)
    80003d68:	ec4e                	sd	s3,24(sp)
    80003d6a:	e852                	sd	s4,16(sp)
    80003d6c:	e456                	sd	s5,8(sp)
    80003d6e:	e05a                	sd	s6,0(sp)
    80003d70:	8aaa                	mv	s5,a0
    80003d72:	8b2e                	mv	s6,a1
    80003d74:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d76:	00026a17          	auipc	s4,0x26
    80003d7a:	002a0a13          	addi	s4,s4,2 # 80029d78 <sb>
    80003d7e:	00495593          	srli	a1,s2,0x4
    80003d82:	018a2783          	lw	a5,24(s4)
    80003d86:	9dbd                	addw	a1,a1,a5
    80003d88:	8556                	mv	a0,s5
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	934080e7          	jalr	-1740(ra) # 800036be <bread>
    80003d92:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d94:	05850993          	addi	s3,a0,88
    80003d98:	00f97793          	andi	a5,s2,15
    80003d9c:	079a                	slli	a5,a5,0x6
    80003d9e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003da0:	00099783          	lh	a5,0(s3)
    80003da4:	cf9d                	beqz	a5,80003de2 <ialloc+0x94>
    brelse(bp);
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	a48080e7          	jalr	-1464(ra) # 800037ee <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dae:	0905                	addi	s2,s2,1
    80003db0:	00ca2703          	lw	a4,12(s4)
    80003db4:	0009079b          	sext.w	a5,s2
    80003db8:	fce7e3e3          	bltu	a5,a4,80003d7e <ialloc+0x30>
    80003dbc:	74a2                	ld	s1,40(sp)
    80003dbe:	7902                	ld	s2,32(sp)
    80003dc0:	69e2                	ld	s3,24(sp)
    80003dc2:	6a42                	ld	s4,16(sp)
    80003dc4:	6aa2                	ld	s5,8(sp)
    80003dc6:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003dc8:	00004517          	auipc	a0,0x4
    80003dcc:	6d850513          	addi	a0,a0,1752 # 800084a0 <etext+0x4a0>
    80003dd0:	ffffc097          	auipc	ra,0xffffc
    80003dd4:	7da080e7          	jalr	2010(ra) # 800005aa <printf>
  return 0;
    80003dd8:	4501                	li	a0,0
}
    80003dda:	70e2                	ld	ra,56(sp)
    80003ddc:	7442                	ld	s0,48(sp)
    80003dde:	6121                	addi	sp,sp,64
    80003de0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003de2:	04000613          	li	a2,64
    80003de6:	4581                	li	a1,0
    80003de8:	854e                	mv	a0,s3
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	f4a080e7          	jalr	-182(ra) # 80000d34 <memset>
      dip->type = type;
    80003df2:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003df6:	8526                	mv	a0,s1
    80003df8:	00001097          	auipc	ra,0x1
    80003dfc:	ca0080e7          	jalr	-864(ra) # 80004a98 <log_write>
      brelse(bp);
    80003e00:	8526                	mv	a0,s1
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	9ec080e7          	jalr	-1556(ra) # 800037ee <brelse>
      return iget(dev, inum);
    80003e0a:	0009059b          	sext.w	a1,s2
    80003e0e:	8556                	mv	a0,s5
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	da2080e7          	jalr	-606(ra) # 80003bb2 <iget>
    80003e18:	74a2                	ld	s1,40(sp)
    80003e1a:	7902                	ld	s2,32(sp)
    80003e1c:	69e2                	ld	s3,24(sp)
    80003e1e:	6a42                	ld	s4,16(sp)
    80003e20:	6aa2                	ld	s5,8(sp)
    80003e22:	6b02                	ld	s6,0(sp)
    80003e24:	bf5d                	j	80003dda <ialloc+0x8c>

0000000080003e26 <iupdate>:
{
    80003e26:	1101                	addi	sp,sp,-32
    80003e28:	ec06                	sd	ra,24(sp)
    80003e2a:	e822                	sd	s0,16(sp)
    80003e2c:	e426                	sd	s1,8(sp)
    80003e2e:	e04a                	sd	s2,0(sp)
    80003e30:	1000                	addi	s0,sp,32
    80003e32:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e34:	415c                	lw	a5,4(a0)
    80003e36:	0047d79b          	srliw	a5,a5,0x4
    80003e3a:	00026597          	auipc	a1,0x26
    80003e3e:	f565a583          	lw	a1,-170(a1) # 80029d90 <sb+0x18>
    80003e42:	9dbd                	addw	a1,a1,a5
    80003e44:	4108                	lw	a0,0(a0)
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	878080e7          	jalr	-1928(ra) # 800036be <bread>
    80003e4e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e50:	05850793          	addi	a5,a0,88
    80003e54:	40d8                	lw	a4,4(s1)
    80003e56:	8b3d                	andi	a4,a4,15
    80003e58:	071a                	slli	a4,a4,0x6
    80003e5a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003e5c:	04449703          	lh	a4,68(s1)
    80003e60:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003e64:	04649703          	lh	a4,70(s1)
    80003e68:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003e6c:	04849703          	lh	a4,72(s1)
    80003e70:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003e74:	04a49703          	lh	a4,74(s1)
    80003e78:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003e7c:	44f8                	lw	a4,76(s1)
    80003e7e:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e80:	03400613          	li	a2,52
    80003e84:	05048593          	addi	a1,s1,80
    80003e88:	00c78513          	addi	a0,a5,12
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	f04080e7          	jalr	-252(ra) # 80000d90 <memmove>
  log_write(bp);
    80003e94:	854a                	mv	a0,s2
    80003e96:	00001097          	auipc	ra,0x1
    80003e9a:	c02080e7          	jalr	-1022(ra) # 80004a98 <log_write>
  brelse(bp);
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	94e080e7          	jalr	-1714(ra) # 800037ee <brelse>
}
    80003ea8:	60e2                	ld	ra,24(sp)
    80003eaa:	6442                	ld	s0,16(sp)
    80003eac:	64a2                	ld	s1,8(sp)
    80003eae:	6902                	ld	s2,0(sp)
    80003eb0:	6105                	addi	sp,sp,32
    80003eb2:	8082                	ret

0000000080003eb4 <idup>:
{
    80003eb4:	1101                	addi	sp,sp,-32
    80003eb6:	ec06                	sd	ra,24(sp)
    80003eb8:	e822                	sd	s0,16(sp)
    80003eba:	e426                	sd	s1,8(sp)
    80003ebc:	1000                	addi	s0,sp,32
    80003ebe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ec0:	00026517          	auipc	a0,0x26
    80003ec4:	ed850513          	addi	a0,a0,-296 # 80029d98 <itable>
    80003ec8:	ffffd097          	auipc	ra,0xffffd
    80003ecc:	d70080e7          	jalr	-656(ra) # 80000c38 <acquire>
  ip->ref++;
    80003ed0:	449c                	lw	a5,8(s1)
    80003ed2:	2785                	addiw	a5,a5,1
    80003ed4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ed6:	00026517          	auipc	a0,0x26
    80003eda:	ec250513          	addi	a0,a0,-318 # 80029d98 <itable>
    80003ede:	ffffd097          	auipc	ra,0xffffd
    80003ee2:	e0e080e7          	jalr	-498(ra) # 80000cec <release>
}
    80003ee6:	8526                	mv	a0,s1
    80003ee8:	60e2                	ld	ra,24(sp)
    80003eea:	6442                	ld	s0,16(sp)
    80003eec:	64a2                	ld	s1,8(sp)
    80003eee:	6105                	addi	sp,sp,32
    80003ef0:	8082                	ret

0000000080003ef2 <ilock>:
{
    80003ef2:	1101                	addi	sp,sp,-32
    80003ef4:	ec06                	sd	ra,24(sp)
    80003ef6:	e822                	sd	s0,16(sp)
    80003ef8:	e426                	sd	s1,8(sp)
    80003efa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003efc:	c10d                	beqz	a0,80003f1e <ilock+0x2c>
    80003efe:	84aa                	mv	s1,a0
    80003f00:	451c                	lw	a5,8(a0)
    80003f02:	00f05e63          	blez	a5,80003f1e <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003f06:	0541                	addi	a0,a0,16
    80003f08:	00001097          	auipc	ra,0x1
    80003f0c:	cae080e7          	jalr	-850(ra) # 80004bb6 <acquiresleep>
  if(ip->valid == 0){
    80003f10:	40bc                	lw	a5,64(s1)
    80003f12:	cf99                	beqz	a5,80003f30 <ilock+0x3e>
}
    80003f14:	60e2                	ld	ra,24(sp)
    80003f16:	6442                	ld	s0,16(sp)
    80003f18:	64a2                	ld	s1,8(sp)
    80003f1a:	6105                	addi	sp,sp,32
    80003f1c:	8082                	ret
    80003f1e:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003f20:	00004517          	auipc	a0,0x4
    80003f24:	59850513          	addi	a0,a0,1432 # 800084b8 <etext+0x4b8>
    80003f28:	ffffc097          	auipc	ra,0xffffc
    80003f2c:	638080e7          	jalr	1592(ra) # 80000560 <panic>
    80003f30:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f32:	40dc                	lw	a5,4(s1)
    80003f34:	0047d79b          	srliw	a5,a5,0x4
    80003f38:	00026597          	auipc	a1,0x26
    80003f3c:	e585a583          	lw	a1,-424(a1) # 80029d90 <sb+0x18>
    80003f40:	9dbd                	addw	a1,a1,a5
    80003f42:	4088                	lw	a0,0(s1)
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	77a080e7          	jalr	1914(ra) # 800036be <bread>
    80003f4c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f4e:	05850593          	addi	a1,a0,88
    80003f52:	40dc                	lw	a5,4(s1)
    80003f54:	8bbd                	andi	a5,a5,15
    80003f56:	079a                	slli	a5,a5,0x6
    80003f58:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f5a:	00059783          	lh	a5,0(a1)
    80003f5e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f62:	00259783          	lh	a5,2(a1)
    80003f66:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f6a:	00459783          	lh	a5,4(a1)
    80003f6e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f72:	00659783          	lh	a5,6(a1)
    80003f76:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f7a:	459c                	lw	a5,8(a1)
    80003f7c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f7e:	03400613          	li	a2,52
    80003f82:	05b1                	addi	a1,a1,12
    80003f84:	05048513          	addi	a0,s1,80
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	e08080e7          	jalr	-504(ra) # 80000d90 <memmove>
    brelse(bp);
    80003f90:	854a                	mv	a0,s2
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	85c080e7          	jalr	-1956(ra) # 800037ee <brelse>
    ip->valid = 1;
    80003f9a:	4785                	li	a5,1
    80003f9c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f9e:	04449783          	lh	a5,68(s1)
    80003fa2:	c399                	beqz	a5,80003fa8 <ilock+0xb6>
    80003fa4:	6902                	ld	s2,0(sp)
    80003fa6:	b7bd                	j	80003f14 <ilock+0x22>
      panic("ilock: no type");
    80003fa8:	00004517          	auipc	a0,0x4
    80003fac:	51850513          	addi	a0,a0,1304 # 800084c0 <etext+0x4c0>
    80003fb0:	ffffc097          	auipc	ra,0xffffc
    80003fb4:	5b0080e7          	jalr	1456(ra) # 80000560 <panic>

0000000080003fb8 <iunlock>:
{
    80003fb8:	1101                	addi	sp,sp,-32
    80003fba:	ec06                	sd	ra,24(sp)
    80003fbc:	e822                	sd	s0,16(sp)
    80003fbe:	e426                	sd	s1,8(sp)
    80003fc0:	e04a                	sd	s2,0(sp)
    80003fc2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fc4:	c905                	beqz	a0,80003ff4 <iunlock+0x3c>
    80003fc6:	84aa                	mv	s1,a0
    80003fc8:	01050913          	addi	s2,a0,16
    80003fcc:	854a                	mv	a0,s2
    80003fce:	00001097          	auipc	ra,0x1
    80003fd2:	c82080e7          	jalr	-894(ra) # 80004c50 <holdingsleep>
    80003fd6:	cd19                	beqz	a0,80003ff4 <iunlock+0x3c>
    80003fd8:	449c                	lw	a5,8(s1)
    80003fda:	00f05d63          	blez	a5,80003ff4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fde:	854a                	mv	a0,s2
    80003fe0:	00001097          	auipc	ra,0x1
    80003fe4:	c2c080e7          	jalr	-980(ra) # 80004c0c <releasesleep>
}
    80003fe8:	60e2                	ld	ra,24(sp)
    80003fea:	6442                	ld	s0,16(sp)
    80003fec:	64a2                	ld	s1,8(sp)
    80003fee:	6902                	ld	s2,0(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret
    panic("iunlock");
    80003ff4:	00004517          	auipc	a0,0x4
    80003ff8:	4dc50513          	addi	a0,a0,1244 # 800084d0 <etext+0x4d0>
    80003ffc:	ffffc097          	auipc	ra,0xffffc
    80004000:	564080e7          	jalr	1380(ra) # 80000560 <panic>

0000000080004004 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004004:	7179                	addi	sp,sp,-48
    80004006:	f406                	sd	ra,40(sp)
    80004008:	f022                	sd	s0,32(sp)
    8000400a:	ec26                	sd	s1,24(sp)
    8000400c:	e84a                	sd	s2,16(sp)
    8000400e:	e44e                	sd	s3,8(sp)
    80004010:	1800                	addi	s0,sp,48
    80004012:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004014:	05050493          	addi	s1,a0,80
    80004018:	08050913          	addi	s2,a0,128
    8000401c:	a021                	j	80004024 <itrunc+0x20>
    8000401e:	0491                	addi	s1,s1,4
    80004020:	01248d63          	beq	s1,s2,8000403a <itrunc+0x36>
    if(ip->addrs[i]){
    80004024:	408c                	lw	a1,0(s1)
    80004026:	dde5                	beqz	a1,8000401e <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80004028:	0009a503          	lw	a0,0(s3)
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	8d6080e7          	jalr	-1834(ra) # 80003902 <bfree>
      ip->addrs[i] = 0;
    80004034:	0004a023          	sw	zero,0(s1)
    80004038:	b7dd                	j	8000401e <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000403a:	0809a583          	lw	a1,128(s3)
    8000403e:	ed99                	bnez	a1,8000405c <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004040:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	de0080e7          	jalr	-544(ra) # 80003e26 <iupdate>
}
    8000404e:	70a2                	ld	ra,40(sp)
    80004050:	7402                	ld	s0,32(sp)
    80004052:	64e2                	ld	s1,24(sp)
    80004054:	6942                	ld	s2,16(sp)
    80004056:	69a2                	ld	s3,8(sp)
    80004058:	6145                	addi	sp,sp,48
    8000405a:	8082                	ret
    8000405c:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000405e:	0009a503          	lw	a0,0(s3)
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	65c080e7          	jalr	1628(ra) # 800036be <bread>
    8000406a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000406c:	05850493          	addi	s1,a0,88
    80004070:	45850913          	addi	s2,a0,1112
    80004074:	a021                	j	8000407c <itrunc+0x78>
    80004076:	0491                	addi	s1,s1,4
    80004078:	01248b63          	beq	s1,s2,8000408e <itrunc+0x8a>
      if(a[j])
    8000407c:	408c                	lw	a1,0(s1)
    8000407e:	dde5                	beqz	a1,80004076 <itrunc+0x72>
        bfree(ip->dev, a[j]);
    80004080:	0009a503          	lw	a0,0(s3)
    80004084:	00000097          	auipc	ra,0x0
    80004088:	87e080e7          	jalr	-1922(ra) # 80003902 <bfree>
    8000408c:	b7ed                	j	80004076 <itrunc+0x72>
    brelse(bp);
    8000408e:	8552                	mv	a0,s4
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	75e080e7          	jalr	1886(ra) # 800037ee <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004098:	0809a583          	lw	a1,128(s3)
    8000409c:	0009a503          	lw	a0,0(s3)
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	862080e7          	jalr	-1950(ra) # 80003902 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040a8:	0809a023          	sw	zero,128(s3)
    800040ac:	6a02                	ld	s4,0(sp)
    800040ae:	bf49                	j	80004040 <itrunc+0x3c>

00000000800040b0 <iput>:
{
    800040b0:	1101                	addi	sp,sp,-32
    800040b2:	ec06                	sd	ra,24(sp)
    800040b4:	e822                	sd	s0,16(sp)
    800040b6:	e426                	sd	s1,8(sp)
    800040b8:	1000                	addi	s0,sp,32
    800040ba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040bc:	00026517          	auipc	a0,0x26
    800040c0:	cdc50513          	addi	a0,a0,-804 # 80029d98 <itable>
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	b74080e7          	jalr	-1164(ra) # 80000c38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040cc:	4498                	lw	a4,8(s1)
    800040ce:	4785                	li	a5,1
    800040d0:	02f70263          	beq	a4,a5,800040f4 <iput+0x44>
  ip->ref--;
    800040d4:	449c                	lw	a5,8(s1)
    800040d6:	37fd                	addiw	a5,a5,-1
    800040d8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040da:	00026517          	auipc	a0,0x26
    800040de:	cbe50513          	addi	a0,a0,-834 # 80029d98 <itable>
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	c0a080e7          	jalr	-1014(ra) # 80000cec <release>
}
    800040ea:	60e2                	ld	ra,24(sp)
    800040ec:	6442                	ld	s0,16(sp)
    800040ee:	64a2                	ld	s1,8(sp)
    800040f0:	6105                	addi	sp,sp,32
    800040f2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040f4:	40bc                	lw	a5,64(s1)
    800040f6:	dff9                	beqz	a5,800040d4 <iput+0x24>
    800040f8:	04a49783          	lh	a5,74(s1)
    800040fc:	ffe1                	bnez	a5,800040d4 <iput+0x24>
    800040fe:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80004100:	01048913          	addi	s2,s1,16
    80004104:	854a                	mv	a0,s2
    80004106:	00001097          	auipc	ra,0x1
    8000410a:	ab0080e7          	jalr	-1360(ra) # 80004bb6 <acquiresleep>
    release(&itable.lock);
    8000410e:	00026517          	auipc	a0,0x26
    80004112:	c8a50513          	addi	a0,a0,-886 # 80029d98 <itable>
    80004116:	ffffd097          	auipc	ra,0xffffd
    8000411a:	bd6080e7          	jalr	-1066(ra) # 80000cec <release>
    itrunc(ip);
    8000411e:	8526                	mv	a0,s1
    80004120:	00000097          	auipc	ra,0x0
    80004124:	ee4080e7          	jalr	-284(ra) # 80004004 <itrunc>
    ip->type = 0;
    80004128:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000412c:	8526                	mv	a0,s1
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	cf8080e7          	jalr	-776(ra) # 80003e26 <iupdate>
    ip->valid = 0;
    80004136:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000413a:	854a                	mv	a0,s2
    8000413c:	00001097          	auipc	ra,0x1
    80004140:	ad0080e7          	jalr	-1328(ra) # 80004c0c <releasesleep>
    acquire(&itable.lock);
    80004144:	00026517          	auipc	a0,0x26
    80004148:	c5450513          	addi	a0,a0,-940 # 80029d98 <itable>
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	aec080e7          	jalr	-1300(ra) # 80000c38 <acquire>
    80004154:	6902                	ld	s2,0(sp)
    80004156:	bfbd                	j	800040d4 <iput+0x24>

0000000080004158 <iunlockput>:
{
    80004158:	1101                	addi	sp,sp,-32
    8000415a:	ec06                	sd	ra,24(sp)
    8000415c:	e822                	sd	s0,16(sp)
    8000415e:	e426                	sd	s1,8(sp)
    80004160:	1000                	addi	s0,sp,32
    80004162:	84aa                	mv	s1,a0
  iunlock(ip);
    80004164:	00000097          	auipc	ra,0x0
    80004168:	e54080e7          	jalr	-428(ra) # 80003fb8 <iunlock>
  iput(ip);
    8000416c:	8526                	mv	a0,s1
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	f42080e7          	jalr	-190(ra) # 800040b0 <iput>
}
    80004176:	60e2                	ld	ra,24(sp)
    80004178:	6442                	ld	s0,16(sp)
    8000417a:	64a2                	ld	s1,8(sp)
    8000417c:	6105                	addi	sp,sp,32
    8000417e:	8082                	ret

0000000080004180 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004180:	1141                	addi	sp,sp,-16
    80004182:	e422                	sd	s0,8(sp)
    80004184:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004186:	411c                	lw	a5,0(a0)
    80004188:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000418a:	415c                	lw	a5,4(a0)
    8000418c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000418e:	04451783          	lh	a5,68(a0)
    80004192:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004196:	04a51783          	lh	a5,74(a0)
    8000419a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000419e:	04c56783          	lwu	a5,76(a0)
    800041a2:	e99c                	sd	a5,16(a1)
}
    800041a4:	6422                	ld	s0,8(sp)
    800041a6:	0141                	addi	sp,sp,16
    800041a8:	8082                	ret

00000000800041aa <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041aa:	457c                	lw	a5,76(a0)
    800041ac:	10d7e563          	bltu	a5,a3,800042b6 <readi+0x10c>
{
    800041b0:	7159                	addi	sp,sp,-112
    800041b2:	f486                	sd	ra,104(sp)
    800041b4:	f0a2                	sd	s0,96(sp)
    800041b6:	eca6                	sd	s1,88(sp)
    800041b8:	e0d2                	sd	s4,64(sp)
    800041ba:	fc56                	sd	s5,56(sp)
    800041bc:	f85a                	sd	s6,48(sp)
    800041be:	f45e                	sd	s7,40(sp)
    800041c0:	1880                	addi	s0,sp,112
    800041c2:	8b2a                	mv	s6,a0
    800041c4:	8bae                	mv	s7,a1
    800041c6:	8a32                	mv	s4,a2
    800041c8:	84b6                	mv	s1,a3
    800041ca:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800041cc:	9f35                	addw	a4,a4,a3
    return 0;
    800041ce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041d0:	0cd76a63          	bltu	a4,a3,800042a4 <readi+0xfa>
    800041d4:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    800041d6:	00e7f463          	bgeu	a5,a4,800041de <readi+0x34>
    n = ip->size - off;
    800041da:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041de:	0a0a8963          	beqz	s5,80004290 <readi+0xe6>
    800041e2:	e8ca                	sd	s2,80(sp)
    800041e4:	f062                	sd	s8,32(sp)
    800041e6:	ec66                	sd	s9,24(sp)
    800041e8:	e86a                	sd	s10,16(sp)
    800041ea:	e46e                	sd	s11,8(sp)
    800041ec:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ee:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041f2:	5c7d                	li	s8,-1
    800041f4:	a82d                	j	8000422e <readi+0x84>
    800041f6:	020d1d93          	slli	s11,s10,0x20
    800041fa:	020ddd93          	srli	s11,s11,0x20
    800041fe:	05890613          	addi	a2,s2,88
    80004202:	86ee                	mv	a3,s11
    80004204:	963a                	add	a2,a2,a4
    80004206:	85d2                	mv	a1,s4
    80004208:	855e                	mv	a0,s7
    8000420a:	ffffe097          	auipc	ra,0xffffe
    8000420e:	70e080e7          	jalr	1806(ra) # 80002918 <either_copyout>
    80004212:	05850d63          	beq	a0,s8,8000426c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004216:	854a                	mv	a0,s2
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	5d6080e7          	jalr	1494(ra) # 800037ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004220:	013d09bb          	addw	s3,s10,s3
    80004224:	009d04bb          	addw	s1,s10,s1
    80004228:	9a6e                	add	s4,s4,s11
    8000422a:	0559fd63          	bgeu	s3,s5,80004284 <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    8000422e:	00a4d59b          	srliw	a1,s1,0xa
    80004232:	855a                	mv	a0,s6
    80004234:	00000097          	auipc	ra,0x0
    80004238:	88e080e7          	jalr	-1906(ra) # 80003ac2 <bmap>
    8000423c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004240:	c9b1                	beqz	a1,80004294 <readi+0xea>
    bp = bread(ip->dev, addr);
    80004242:	000b2503          	lw	a0,0(s6)
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	478080e7          	jalr	1144(ra) # 800036be <bread>
    8000424e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004250:	3ff4f713          	andi	a4,s1,1023
    80004254:	40ec87bb          	subw	a5,s9,a4
    80004258:	413a86bb          	subw	a3,s5,s3
    8000425c:	8d3e                	mv	s10,a5
    8000425e:	2781                	sext.w	a5,a5
    80004260:	0006861b          	sext.w	a2,a3
    80004264:	f8f679e3          	bgeu	a2,a5,800041f6 <readi+0x4c>
    80004268:	8d36                	mv	s10,a3
    8000426a:	b771                	j	800041f6 <readi+0x4c>
      brelse(bp);
    8000426c:	854a                	mv	a0,s2
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	580080e7          	jalr	1408(ra) # 800037ee <brelse>
      tot = -1;
    80004276:	59fd                	li	s3,-1
      break;
    80004278:	6946                	ld	s2,80(sp)
    8000427a:	7c02                	ld	s8,32(sp)
    8000427c:	6ce2                	ld	s9,24(sp)
    8000427e:	6d42                	ld	s10,16(sp)
    80004280:	6da2                	ld	s11,8(sp)
    80004282:	a831                	j	8000429e <readi+0xf4>
    80004284:	6946                	ld	s2,80(sp)
    80004286:	7c02                	ld	s8,32(sp)
    80004288:	6ce2                	ld	s9,24(sp)
    8000428a:	6d42                	ld	s10,16(sp)
    8000428c:	6da2                	ld	s11,8(sp)
    8000428e:	a801                	j	8000429e <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004290:	89d6                	mv	s3,s5
    80004292:	a031                	j	8000429e <readi+0xf4>
    80004294:	6946                	ld	s2,80(sp)
    80004296:	7c02                	ld	s8,32(sp)
    80004298:	6ce2                	ld	s9,24(sp)
    8000429a:	6d42                	ld	s10,16(sp)
    8000429c:	6da2                	ld	s11,8(sp)
  }
  return tot;
    8000429e:	0009851b          	sext.w	a0,s3
    800042a2:	69a6                	ld	s3,72(sp)
}
    800042a4:	70a6                	ld	ra,104(sp)
    800042a6:	7406                	ld	s0,96(sp)
    800042a8:	64e6                	ld	s1,88(sp)
    800042aa:	6a06                	ld	s4,64(sp)
    800042ac:	7ae2                	ld	s5,56(sp)
    800042ae:	7b42                	ld	s6,48(sp)
    800042b0:	7ba2                	ld	s7,40(sp)
    800042b2:	6165                	addi	sp,sp,112
    800042b4:	8082                	ret
    return 0;
    800042b6:	4501                	li	a0,0
}
    800042b8:	8082                	ret

00000000800042ba <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042ba:	457c                	lw	a5,76(a0)
    800042bc:	10d7ee63          	bltu	a5,a3,800043d8 <writei+0x11e>
{
    800042c0:	7159                	addi	sp,sp,-112
    800042c2:	f486                	sd	ra,104(sp)
    800042c4:	f0a2                	sd	s0,96(sp)
    800042c6:	e8ca                	sd	s2,80(sp)
    800042c8:	e0d2                	sd	s4,64(sp)
    800042ca:	fc56                	sd	s5,56(sp)
    800042cc:	f85a                	sd	s6,48(sp)
    800042ce:	f45e                	sd	s7,40(sp)
    800042d0:	1880                	addi	s0,sp,112
    800042d2:	8aaa                	mv	s5,a0
    800042d4:	8bae                	mv	s7,a1
    800042d6:	8a32                	mv	s4,a2
    800042d8:	8936                	mv	s2,a3
    800042da:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042dc:	00e687bb          	addw	a5,a3,a4
    800042e0:	0ed7ee63          	bltu	a5,a3,800043dc <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042e4:	00043737          	lui	a4,0x43
    800042e8:	0ef76c63          	bltu	a4,a5,800043e0 <writei+0x126>
    800042ec:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ee:	0c0b0d63          	beqz	s6,800043c8 <writei+0x10e>
    800042f2:	eca6                	sd	s1,88(sp)
    800042f4:	f062                	sd	s8,32(sp)
    800042f6:	ec66                	sd	s9,24(sp)
    800042f8:	e86a                	sd	s10,16(sp)
    800042fa:	e46e                	sd	s11,8(sp)
    800042fc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042fe:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004302:	5c7d                	li	s8,-1
    80004304:	a091                	j	80004348 <writei+0x8e>
    80004306:	020d1d93          	slli	s11,s10,0x20
    8000430a:	020ddd93          	srli	s11,s11,0x20
    8000430e:	05848513          	addi	a0,s1,88
    80004312:	86ee                	mv	a3,s11
    80004314:	8652                	mv	a2,s4
    80004316:	85de                	mv	a1,s7
    80004318:	953a                	add	a0,a0,a4
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	656080e7          	jalr	1622(ra) # 80002970 <either_copyin>
    80004322:	07850263          	beq	a0,s8,80004386 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004326:	8526                	mv	a0,s1
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	770080e7          	jalr	1904(ra) # 80004a98 <log_write>
    brelse(bp);
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	4bc080e7          	jalr	1212(ra) # 800037ee <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000433a:	013d09bb          	addw	s3,s10,s3
    8000433e:	012d093b          	addw	s2,s10,s2
    80004342:	9a6e                	add	s4,s4,s11
    80004344:	0569f663          	bgeu	s3,s6,80004390 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004348:	00a9559b          	srliw	a1,s2,0xa
    8000434c:	8556                	mv	a0,s5
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	774080e7          	jalr	1908(ra) # 80003ac2 <bmap>
    80004356:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000435a:	c99d                	beqz	a1,80004390 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000435c:	000aa503          	lw	a0,0(s5)
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	35e080e7          	jalr	862(ra) # 800036be <bread>
    80004368:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000436a:	3ff97713          	andi	a4,s2,1023
    8000436e:	40ec87bb          	subw	a5,s9,a4
    80004372:	413b06bb          	subw	a3,s6,s3
    80004376:	8d3e                	mv	s10,a5
    80004378:	2781                	sext.w	a5,a5
    8000437a:	0006861b          	sext.w	a2,a3
    8000437e:	f8f674e3          	bgeu	a2,a5,80004306 <writei+0x4c>
    80004382:	8d36                	mv	s10,a3
    80004384:	b749                	j	80004306 <writei+0x4c>
      brelse(bp);
    80004386:	8526                	mv	a0,s1
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	466080e7          	jalr	1126(ra) # 800037ee <brelse>
  }

  if(off > ip->size)
    80004390:	04caa783          	lw	a5,76(s5)
    80004394:	0327fc63          	bgeu	a5,s2,800043cc <writei+0x112>
    ip->size = off;
    80004398:	052aa623          	sw	s2,76(s5)
    8000439c:	64e6                	ld	s1,88(sp)
    8000439e:	7c02                	ld	s8,32(sp)
    800043a0:	6ce2                	ld	s9,24(sp)
    800043a2:	6d42                	ld	s10,16(sp)
    800043a4:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043a6:	8556                	mv	a0,s5
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	a7e080e7          	jalr	-1410(ra) # 80003e26 <iupdate>

  return tot;
    800043b0:	0009851b          	sext.w	a0,s3
    800043b4:	69a6                	ld	s3,72(sp)
}
    800043b6:	70a6                	ld	ra,104(sp)
    800043b8:	7406                	ld	s0,96(sp)
    800043ba:	6946                	ld	s2,80(sp)
    800043bc:	6a06                	ld	s4,64(sp)
    800043be:	7ae2                	ld	s5,56(sp)
    800043c0:	7b42                	ld	s6,48(sp)
    800043c2:	7ba2                	ld	s7,40(sp)
    800043c4:	6165                	addi	sp,sp,112
    800043c6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043c8:	89da                	mv	s3,s6
    800043ca:	bff1                	j	800043a6 <writei+0xec>
    800043cc:	64e6                	ld	s1,88(sp)
    800043ce:	7c02                	ld	s8,32(sp)
    800043d0:	6ce2                	ld	s9,24(sp)
    800043d2:	6d42                	ld	s10,16(sp)
    800043d4:	6da2                	ld	s11,8(sp)
    800043d6:	bfc1                	j	800043a6 <writei+0xec>
    return -1;
    800043d8:	557d                	li	a0,-1
}
    800043da:	8082                	ret
    return -1;
    800043dc:	557d                	li	a0,-1
    800043de:	bfe1                	j	800043b6 <writei+0xfc>
    return -1;
    800043e0:	557d                	li	a0,-1
    800043e2:	bfd1                	j	800043b6 <writei+0xfc>

00000000800043e4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043e4:	1141                	addi	sp,sp,-16
    800043e6:	e406                	sd	ra,8(sp)
    800043e8:	e022                	sd	s0,0(sp)
    800043ea:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043ec:	4639                	li	a2,14
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	a16080e7          	jalr	-1514(ra) # 80000e04 <strncmp>
}
    800043f6:	60a2                	ld	ra,8(sp)
    800043f8:	6402                	ld	s0,0(sp)
    800043fa:	0141                	addi	sp,sp,16
    800043fc:	8082                	ret

00000000800043fe <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043fe:	7139                	addi	sp,sp,-64
    80004400:	fc06                	sd	ra,56(sp)
    80004402:	f822                	sd	s0,48(sp)
    80004404:	f426                	sd	s1,40(sp)
    80004406:	f04a                	sd	s2,32(sp)
    80004408:	ec4e                	sd	s3,24(sp)
    8000440a:	e852                	sd	s4,16(sp)
    8000440c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000440e:	04451703          	lh	a4,68(a0)
    80004412:	4785                	li	a5,1
    80004414:	00f71a63          	bne	a4,a5,80004428 <dirlookup+0x2a>
    80004418:	892a                	mv	s2,a0
    8000441a:	89ae                	mv	s3,a1
    8000441c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000441e:	457c                	lw	a5,76(a0)
    80004420:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004422:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004424:	e79d                	bnez	a5,80004452 <dirlookup+0x54>
    80004426:	a8a5                	j	8000449e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004428:	00004517          	auipc	a0,0x4
    8000442c:	0b050513          	addi	a0,a0,176 # 800084d8 <etext+0x4d8>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	130080e7          	jalr	304(ra) # 80000560 <panic>
      panic("dirlookup read");
    80004438:	00004517          	auipc	a0,0x4
    8000443c:	0b850513          	addi	a0,a0,184 # 800084f0 <etext+0x4f0>
    80004440:	ffffc097          	auipc	ra,0xffffc
    80004444:	120080e7          	jalr	288(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004448:	24c1                	addiw	s1,s1,16
    8000444a:	04c92783          	lw	a5,76(s2)
    8000444e:	04f4f763          	bgeu	s1,a5,8000449c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004452:	4741                	li	a4,16
    80004454:	86a6                	mv	a3,s1
    80004456:	fc040613          	addi	a2,s0,-64
    8000445a:	4581                	li	a1,0
    8000445c:	854a                	mv	a0,s2
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	d4c080e7          	jalr	-692(ra) # 800041aa <readi>
    80004466:	47c1                	li	a5,16
    80004468:	fcf518e3          	bne	a0,a5,80004438 <dirlookup+0x3a>
    if(de.inum == 0)
    8000446c:	fc045783          	lhu	a5,-64(s0)
    80004470:	dfe1                	beqz	a5,80004448 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004472:	fc240593          	addi	a1,s0,-62
    80004476:	854e                	mv	a0,s3
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	f6c080e7          	jalr	-148(ra) # 800043e4 <namecmp>
    80004480:	f561                	bnez	a0,80004448 <dirlookup+0x4a>
      if(poff)
    80004482:	000a0463          	beqz	s4,8000448a <dirlookup+0x8c>
        *poff = off;
    80004486:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000448a:	fc045583          	lhu	a1,-64(s0)
    8000448e:	00092503          	lw	a0,0(s2)
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	720080e7          	jalr	1824(ra) # 80003bb2 <iget>
    8000449a:	a011                	j	8000449e <dirlookup+0xa0>
  return 0;
    8000449c:	4501                	li	a0,0
}
    8000449e:	70e2                	ld	ra,56(sp)
    800044a0:	7442                	ld	s0,48(sp)
    800044a2:	74a2                	ld	s1,40(sp)
    800044a4:	7902                	ld	s2,32(sp)
    800044a6:	69e2                	ld	s3,24(sp)
    800044a8:	6a42                	ld	s4,16(sp)
    800044aa:	6121                	addi	sp,sp,64
    800044ac:	8082                	ret

00000000800044ae <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044ae:	711d                	addi	sp,sp,-96
    800044b0:	ec86                	sd	ra,88(sp)
    800044b2:	e8a2                	sd	s0,80(sp)
    800044b4:	e4a6                	sd	s1,72(sp)
    800044b6:	e0ca                	sd	s2,64(sp)
    800044b8:	fc4e                	sd	s3,56(sp)
    800044ba:	f852                	sd	s4,48(sp)
    800044bc:	f456                	sd	s5,40(sp)
    800044be:	f05a                	sd	s6,32(sp)
    800044c0:	ec5e                	sd	s7,24(sp)
    800044c2:	e862                	sd	s8,16(sp)
    800044c4:	e466                	sd	s9,8(sp)
    800044c6:	1080                	addi	s0,sp,96
    800044c8:	84aa                	mv	s1,a0
    800044ca:	8b2e                	mv	s6,a1
    800044cc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044ce:	00054703          	lbu	a4,0(a0)
    800044d2:	02f00793          	li	a5,47
    800044d6:	02f70263          	beq	a4,a5,800044fa <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044da:	ffffd097          	auipc	ra,0xffffd
    800044de:	5a0080e7          	jalr	1440(ra) # 80001a7a <myproc>
    800044e2:	32853503          	ld	a0,808(a0)
    800044e6:	00000097          	auipc	ra,0x0
    800044ea:	9ce080e7          	jalr	-1586(ra) # 80003eb4 <idup>
    800044ee:	8a2a                	mv	s4,a0
  while(*path == '/')
    800044f0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800044f4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044f6:	4b85                	li	s7,1
    800044f8:	a875                	j	800045b4 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800044fa:	4585                	li	a1,1
    800044fc:	4505                	li	a0,1
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	6b4080e7          	jalr	1716(ra) # 80003bb2 <iget>
    80004506:	8a2a                	mv	s4,a0
    80004508:	b7e5                	j	800044f0 <namex+0x42>
      iunlockput(ip);
    8000450a:	8552                	mv	a0,s4
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	c4c080e7          	jalr	-948(ra) # 80004158 <iunlockput>
      return 0;
    80004514:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004516:	8552                	mv	a0,s4
    80004518:	60e6                	ld	ra,88(sp)
    8000451a:	6446                	ld	s0,80(sp)
    8000451c:	64a6                	ld	s1,72(sp)
    8000451e:	6906                	ld	s2,64(sp)
    80004520:	79e2                	ld	s3,56(sp)
    80004522:	7a42                	ld	s4,48(sp)
    80004524:	7aa2                	ld	s5,40(sp)
    80004526:	7b02                	ld	s6,32(sp)
    80004528:	6be2                	ld	s7,24(sp)
    8000452a:	6c42                	ld	s8,16(sp)
    8000452c:	6ca2                	ld	s9,8(sp)
    8000452e:	6125                	addi	sp,sp,96
    80004530:	8082                	ret
      iunlock(ip);
    80004532:	8552                	mv	a0,s4
    80004534:	00000097          	auipc	ra,0x0
    80004538:	a84080e7          	jalr	-1404(ra) # 80003fb8 <iunlock>
      return ip;
    8000453c:	bfe9                	j	80004516 <namex+0x68>
      iunlockput(ip);
    8000453e:	8552                	mv	a0,s4
    80004540:	00000097          	auipc	ra,0x0
    80004544:	c18080e7          	jalr	-1000(ra) # 80004158 <iunlockput>
      return 0;
    80004548:	8a4e                	mv	s4,s3
    8000454a:	b7f1                	j	80004516 <namex+0x68>
  len = path - s;
    8000454c:	40998633          	sub	a2,s3,s1
    80004550:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004554:	099c5863          	bge	s8,s9,800045e4 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004558:	4639                	li	a2,14
    8000455a:	85a6                	mv	a1,s1
    8000455c:	8556                	mv	a0,s5
    8000455e:	ffffd097          	auipc	ra,0xffffd
    80004562:	832080e7          	jalr	-1998(ra) # 80000d90 <memmove>
    80004566:	84ce                	mv	s1,s3
  while(*path == '/')
    80004568:	0004c783          	lbu	a5,0(s1)
    8000456c:	01279763          	bne	a5,s2,8000457a <namex+0xcc>
    path++;
    80004570:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004572:	0004c783          	lbu	a5,0(s1)
    80004576:	ff278de3          	beq	a5,s2,80004570 <namex+0xc2>
    ilock(ip);
    8000457a:	8552                	mv	a0,s4
    8000457c:	00000097          	auipc	ra,0x0
    80004580:	976080e7          	jalr	-1674(ra) # 80003ef2 <ilock>
    if(ip->type != T_DIR){
    80004584:	044a1783          	lh	a5,68(s4)
    80004588:	f97791e3          	bne	a5,s7,8000450a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    8000458c:	000b0563          	beqz	s6,80004596 <namex+0xe8>
    80004590:	0004c783          	lbu	a5,0(s1)
    80004594:	dfd9                	beqz	a5,80004532 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004596:	4601                	li	a2,0
    80004598:	85d6                	mv	a1,s5
    8000459a:	8552                	mv	a0,s4
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	e62080e7          	jalr	-414(ra) # 800043fe <dirlookup>
    800045a4:	89aa                	mv	s3,a0
    800045a6:	dd41                	beqz	a0,8000453e <namex+0x90>
    iunlockput(ip);
    800045a8:	8552                	mv	a0,s4
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	bae080e7          	jalr	-1106(ra) # 80004158 <iunlockput>
    ip = next;
    800045b2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800045b4:	0004c783          	lbu	a5,0(s1)
    800045b8:	01279763          	bne	a5,s2,800045c6 <namex+0x118>
    path++;
    800045bc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045be:	0004c783          	lbu	a5,0(s1)
    800045c2:	ff278de3          	beq	a5,s2,800045bc <namex+0x10e>
  if(*path == 0)
    800045c6:	cb9d                	beqz	a5,800045fc <namex+0x14e>
  while(*path != '/' && *path != 0)
    800045c8:	0004c783          	lbu	a5,0(s1)
    800045cc:	89a6                	mv	s3,s1
  len = path - s;
    800045ce:	4c81                	li	s9,0
    800045d0:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800045d2:	01278963          	beq	a5,s2,800045e4 <namex+0x136>
    800045d6:	dbbd                	beqz	a5,8000454c <namex+0x9e>
    path++;
    800045d8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800045da:	0009c783          	lbu	a5,0(s3)
    800045de:	ff279ce3          	bne	a5,s2,800045d6 <namex+0x128>
    800045e2:	b7ad                	j	8000454c <namex+0x9e>
    memmove(name, s, len);
    800045e4:	2601                	sext.w	a2,a2
    800045e6:	85a6                	mv	a1,s1
    800045e8:	8556                	mv	a0,s5
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	7a6080e7          	jalr	1958(ra) # 80000d90 <memmove>
    name[len] = 0;
    800045f2:	9cd6                	add	s9,s9,s5
    800045f4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045f8:	84ce                	mv	s1,s3
    800045fa:	b7bd                	j	80004568 <namex+0xba>
  if(nameiparent){
    800045fc:	f00b0de3          	beqz	s6,80004516 <namex+0x68>
    iput(ip);
    80004600:	8552                	mv	a0,s4
    80004602:	00000097          	auipc	ra,0x0
    80004606:	aae080e7          	jalr	-1362(ra) # 800040b0 <iput>
    return 0;
    8000460a:	4a01                	li	s4,0
    8000460c:	b729                	j	80004516 <namex+0x68>

000000008000460e <dirlink>:
{
    8000460e:	7139                	addi	sp,sp,-64
    80004610:	fc06                	sd	ra,56(sp)
    80004612:	f822                	sd	s0,48(sp)
    80004614:	f04a                	sd	s2,32(sp)
    80004616:	ec4e                	sd	s3,24(sp)
    80004618:	e852                	sd	s4,16(sp)
    8000461a:	0080                	addi	s0,sp,64
    8000461c:	892a                	mv	s2,a0
    8000461e:	8a2e                	mv	s4,a1
    80004620:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004622:	4601                	li	a2,0
    80004624:	00000097          	auipc	ra,0x0
    80004628:	dda080e7          	jalr	-550(ra) # 800043fe <dirlookup>
    8000462c:	ed25                	bnez	a0,800046a4 <dirlink+0x96>
    8000462e:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004630:	04c92483          	lw	s1,76(s2)
    80004634:	c49d                	beqz	s1,80004662 <dirlink+0x54>
    80004636:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004638:	4741                	li	a4,16
    8000463a:	86a6                	mv	a3,s1
    8000463c:	fc040613          	addi	a2,s0,-64
    80004640:	4581                	li	a1,0
    80004642:	854a                	mv	a0,s2
    80004644:	00000097          	auipc	ra,0x0
    80004648:	b66080e7          	jalr	-1178(ra) # 800041aa <readi>
    8000464c:	47c1                	li	a5,16
    8000464e:	06f51163          	bne	a0,a5,800046b0 <dirlink+0xa2>
    if(de.inum == 0)
    80004652:	fc045783          	lhu	a5,-64(s0)
    80004656:	c791                	beqz	a5,80004662 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004658:	24c1                	addiw	s1,s1,16
    8000465a:	04c92783          	lw	a5,76(s2)
    8000465e:	fcf4ede3          	bltu	s1,a5,80004638 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004662:	4639                	li	a2,14
    80004664:	85d2                	mv	a1,s4
    80004666:	fc240513          	addi	a0,s0,-62
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	7d0080e7          	jalr	2000(ra) # 80000e3a <strncpy>
  de.inum = inum;
    80004672:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004676:	4741                	li	a4,16
    80004678:	86a6                	mv	a3,s1
    8000467a:	fc040613          	addi	a2,s0,-64
    8000467e:	4581                	li	a1,0
    80004680:	854a                	mv	a0,s2
    80004682:	00000097          	auipc	ra,0x0
    80004686:	c38080e7          	jalr	-968(ra) # 800042ba <writei>
    8000468a:	1541                	addi	a0,a0,-16
    8000468c:	00a03533          	snez	a0,a0
    80004690:	40a00533          	neg	a0,a0
    80004694:	74a2                	ld	s1,40(sp)
}
    80004696:	70e2                	ld	ra,56(sp)
    80004698:	7442                	ld	s0,48(sp)
    8000469a:	7902                	ld	s2,32(sp)
    8000469c:	69e2                	ld	s3,24(sp)
    8000469e:	6a42                	ld	s4,16(sp)
    800046a0:	6121                	addi	sp,sp,64
    800046a2:	8082                	ret
    iput(ip);
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	a0c080e7          	jalr	-1524(ra) # 800040b0 <iput>
    return -1;
    800046ac:	557d                	li	a0,-1
    800046ae:	b7e5                	j	80004696 <dirlink+0x88>
      panic("dirlink read");
    800046b0:	00004517          	auipc	a0,0x4
    800046b4:	e5050513          	addi	a0,a0,-432 # 80008500 <etext+0x500>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	ea8080e7          	jalr	-344(ra) # 80000560 <panic>

00000000800046c0 <namei>:

struct inode*
namei(char *path)
{
    800046c0:	1101                	addi	sp,sp,-32
    800046c2:	ec06                	sd	ra,24(sp)
    800046c4:	e822                	sd	s0,16(sp)
    800046c6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046c8:	fe040613          	addi	a2,s0,-32
    800046cc:	4581                	li	a1,0
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	de0080e7          	jalr	-544(ra) # 800044ae <namex>
}
    800046d6:	60e2                	ld	ra,24(sp)
    800046d8:	6442                	ld	s0,16(sp)
    800046da:	6105                	addi	sp,sp,32
    800046dc:	8082                	ret

00000000800046de <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046de:	1141                	addi	sp,sp,-16
    800046e0:	e406                	sd	ra,8(sp)
    800046e2:	e022                	sd	s0,0(sp)
    800046e4:	0800                	addi	s0,sp,16
    800046e6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046e8:	4585                	li	a1,1
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	dc4080e7          	jalr	-572(ra) # 800044ae <namex>
}
    800046f2:	60a2                	ld	ra,8(sp)
    800046f4:	6402                	ld	s0,0(sp)
    800046f6:	0141                	addi	sp,sp,16
    800046f8:	8082                	ret

00000000800046fa <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046fa:	1101                	addi	sp,sp,-32
    800046fc:	ec06                	sd	ra,24(sp)
    800046fe:	e822                	sd	s0,16(sp)
    80004700:	e426                	sd	s1,8(sp)
    80004702:	e04a                	sd	s2,0(sp)
    80004704:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004706:	00027917          	auipc	s2,0x27
    8000470a:	13a90913          	addi	s2,s2,314 # 8002b840 <log>
    8000470e:	01892583          	lw	a1,24(s2)
    80004712:	02892503          	lw	a0,40(s2)
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	fa8080e7          	jalr	-88(ra) # 800036be <bread>
    8000471e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004720:	02c92603          	lw	a2,44(s2)
    80004724:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004726:	00c05f63          	blez	a2,80004744 <write_head+0x4a>
    8000472a:	00027717          	auipc	a4,0x27
    8000472e:	14670713          	addi	a4,a4,326 # 8002b870 <log+0x30>
    80004732:	87aa                	mv	a5,a0
    80004734:	060a                	slli	a2,a2,0x2
    80004736:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004738:	4314                	lw	a3,0(a4)
    8000473a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000473c:	0711                	addi	a4,a4,4
    8000473e:	0791                	addi	a5,a5,4
    80004740:	fec79ce3          	bne	a5,a2,80004738 <write_head+0x3e>
  }
  bwrite(buf);
    80004744:	8526                	mv	a0,s1
    80004746:	fffff097          	auipc	ra,0xfffff
    8000474a:	06a080e7          	jalr	106(ra) # 800037b0 <bwrite>
  brelse(buf);
    8000474e:	8526                	mv	a0,s1
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	09e080e7          	jalr	158(ra) # 800037ee <brelse>
}
    80004758:	60e2                	ld	ra,24(sp)
    8000475a:	6442                	ld	s0,16(sp)
    8000475c:	64a2                	ld	s1,8(sp)
    8000475e:	6902                	ld	s2,0(sp)
    80004760:	6105                	addi	sp,sp,32
    80004762:	8082                	ret

0000000080004764 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004764:	00027797          	auipc	a5,0x27
    80004768:	1087a783          	lw	a5,264(a5) # 8002b86c <log+0x2c>
    8000476c:	0af05d63          	blez	a5,80004826 <install_trans+0xc2>
{
    80004770:	7139                	addi	sp,sp,-64
    80004772:	fc06                	sd	ra,56(sp)
    80004774:	f822                	sd	s0,48(sp)
    80004776:	f426                	sd	s1,40(sp)
    80004778:	f04a                	sd	s2,32(sp)
    8000477a:	ec4e                	sd	s3,24(sp)
    8000477c:	e852                	sd	s4,16(sp)
    8000477e:	e456                	sd	s5,8(sp)
    80004780:	e05a                	sd	s6,0(sp)
    80004782:	0080                	addi	s0,sp,64
    80004784:	8b2a                	mv	s6,a0
    80004786:	00027a97          	auipc	s5,0x27
    8000478a:	0eaa8a93          	addi	s5,s5,234 # 8002b870 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000478e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004790:	00027997          	auipc	s3,0x27
    80004794:	0b098993          	addi	s3,s3,176 # 8002b840 <log>
    80004798:	a00d                	j	800047ba <install_trans+0x56>
    brelse(lbuf);
    8000479a:	854a                	mv	a0,s2
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	052080e7          	jalr	82(ra) # 800037ee <brelse>
    brelse(dbuf);
    800047a4:	8526                	mv	a0,s1
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	048080e7          	jalr	72(ra) # 800037ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047ae:	2a05                	addiw	s4,s4,1
    800047b0:	0a91                	addi	s5,s5,4
    800047b2:	02c9a783          	lw	a5,44(s3)
    800047b6:	04fa5e63          	bge	s4,a5,80004812 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047ba:	0189a583          	lw	a1,24(s3)
    800047be:	014585bb          	addw	a1,a1,s4
    800047c2:	2585                	addiw	a1,a1,1
    800047c4:	0289a503          	lw	a0,40(s3)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	ef6080e7          	jalr	-266(ra) # 800036be <bread>
    800047d0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047d2:	000aa583          	lw	a1,0(s5)
    800047d6:	0289a503          	lw	a0,40(s3)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	ee4080e7          	jalr	-284(ra) # 800036be <bread>
    800047e2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047e4:	40000613          	li	a2,1024
    800047e8:	05890593          	addi	a1,s2,88
    800047ec:	05850513          	addi	a0,a0,88
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	5a0080e7          	jalr	1440(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    800047f8:	8526                	mv	a0,s1
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	fb6080e7          	jalr	-74(ra) # 800037b0 <bwrite>
    if(recovering == 0)
    80004802:	f80b1ce3          	bnez	s6,8000479a <install_trans+0x36>
      bunpin(dbuf);
    80004806:	8526                	mv	a0,s1
    80004808:	fffff097          	auipc	ra,0xfffff
    8000480c:	0be080e7          	jalr	190(ra) # 800038c6 <bunpin>
    80004810:	b769                	j	8000479a <install_trans+0x36>
}
    80004812:	70e2                	ld	ra,56(sp)
    80004814:	7442                	ld	s0,48(sp)
    80004816:	74a2                	ld	s1,40(sp)
    80004818:	7902                	ld	s2,32(sp)
    8000481a:	69e2                	ld	s3,24(sp)
    8000481c:	6a42                	ld	s4,16(sp)
    8000481e:	6aa2                	ld	s5,8(sp)
    80004820:	6b02                	ld	s6,0(sp)
    80004822:	6121                	addi	sp,sp,64
    80004824:	8082                	ret
    80004826:	8082                	ret

0000000080004828 <initlog>:
{
    80004828:	7179                	addi	sp,sp,-48
    8000482a:	f406                	sd	ra,40(sp)
    8000482c:	f022                	sd	s0,32(sp)
    8000482e:	ec26                	sd	s1,24(sp)
    80004830:	e84a                	sd	s2,16(sp)
    80004832:	e44e                	sd	s3,8(sp)
    80004834:	1800                	addi	s0,sp,48
    80004836:	892a                	mv	s2,a0
    80004838:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000483a:	00027497          	auipc	s1,0x27
    8000483e:	00648493          	addi	s1,s1,6 # 8002b840 <log>
    80004842:	00004597          	auipc	a1,0x4
    80004846:	cce58593          	addi	a1,a1,-818 # 80008510 <etext+0x510>
    8000484a:	8526                	mv	a0,s1
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	35c080e7          	jalr	860(ra) # 80000ba8 <initlock>
  log.start = sb->logstart;
    80004854:	0149a583          	lw	a1,20(s3)
    80004858:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000485a:	0109a783          	lw	a5,16(s3)
    8000485e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004860:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004864:	854a                	mv	a0,s2
    80004866:	fffff097          	auipc	ra,0xfffff
    8000486a:	e58080e7          	jalr	-424(ra) # 800036be <bread>
  log.lh.n = lh->n;
    8000486e:	4d30                	lw	a2,88(a0)
    80004870:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004872:	00c05f63          	blez	a2,80004890 <initlog+0x68>
    80004876:	87aa                	mv	a5,a0
    80004878:	00027717          	auipc	a4,0x27
    8000487c:	ff870713          	addi	a4,a4,-8 # 8002b870 <log+0x30>
    80004880:	060a                	slli	a2,a2,0x2
    80004882:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004884:	4ff4                	lw	a3,92(a5)
    80004886:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004888:	0791                	addi	a5,a5,4
    8000488a:	0711                	addi	a4,a4,4
    8000488c:	fec79ce3          	bne	a5,a2,80004884 <initlog+0x5c>
  brelse(buf);
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	f5e080e7          	jalr	-162(ra) # 800037ee <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004898:	4505                	li	a0,1
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	eca080e7          	jalr	-310(ra) # 80004764 <install_trans>
  log.lh.n = 0;
    800048a2:	00027797          	auipc	a5,0x27
    800048a6:	fc07a523          	sw	zero,-54(a5) # 8002b86c <log+0x2c>
  write_head(); // clear the log
    800048aa:	00000097          	auipc	ra,0x0
    800048ae:	e50080e7          	jalr	-432(ra) # 800046fa <write_head>
}
    800048b2:	70a2                	ld	ra,40(sp)
    800048b4:	7402                	ld	s0,32(sp)
    800048b6:	64e2                	ld	s1,24(sp)
    800048b8:	6942                	ld	s2,16(sp)
    800048ba:	69a2                	ld	s3,8(sp)
    800048bc:	6145                	addi	sp,sp,48
    800048be:	8082                	ret

00000000800048c0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048c0:	1101                	addi	sp,sp,-32
    800048c2:	ec06                	sd	ra,24(sp)
    800048c4:	e822                	sd	s0,16(sp)
    800048c6:	e426                	sd	s1,8(sp)
    800048c8:	e04a                	sd	s2,0(sp)
    800048ca:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048cc:	00027517          	auipc	a0,0x27
    800048d0:	f7450513          	addi	a0,a0,-140 # 8002b840 <log>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	364080e7          	jalr	868(ra) # 80000c38 <acquire>
  while(1){
    if(log.committing){
    800048dc:	00027497          	auipc	s1,0x27
    800048e0:	f6448493          	addi	s1,s1,-156 # 8002b840 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048e4:	4979                	li	s2,30
    800048e6:	a039                	j	800048f4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800048e8:	85a6                	mv	a1,s1
    800048ea:	8526                	mv	a0,s1
    800048ec:	ffffe097          	auipc	ra,0xffffe
    800048f0:	bf8080e7          	jalr	-1032(ra) # 800024e4 <sleep>
    if(log.committing){
    800048f4:	50dc                	lw	a5,36(s1)
    800048f6:	fbed                	bnez	a5,800048e8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048f8:	5098                	lw	a4,32(s1)
    800048fa:	2705                	addiw	a4,a4,1
    800048fc:	0027179b          	slliw	a5,a4,0x2
    80004900:	9fb9                	addw	a5,a5,a4
    80004902:	0017979b          	slliw	a5,a5,0x1
    80004906:	54d4                	lw	a3,44(s1)
    80004908:	9fb5                	addw	a5,a5,a3
    8000490a:	00f95963          	bge	s2,a5,8000491c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000490e:	85a6                	mv	a1,s1
    80004910:	8526                	mv	a0,s1
    80004912:	ffffe097          	auipc	ra,0xffffe
    80004916:	bd2080e7          	jalr	-1070(ra) # 800024e4 <sleep>
    8000491a:	bfe9                	j	800048f4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000491c:	00027517          	auipc	a0,0x27
    80004920:	f2450513          	addi	a0,a0,-220 # 8002b840 <log>
    80004924:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	3c6080e7          	jalr	966(ra) # 80000cec <release>
      break;
    }
  }
}
    8000492e:	60e2                	ld	ra,24(sp)
    80004930:	6442                	ld	s0,16(sp)
    80004932:	64a2                	ld	s1,8(sp)
    80004934:	6902                	ld	s2,0(sp)
    80004936:	6105                	addi	sp,sp,32
    80004938:	8082                	ret

000000008000493a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000493a:	7139                	addi	sp,sp,-64
    8000493c:	fc06                	sd	ra,56(sp)
    8000493e:	f822                	sd	s0,48(sp)
    80004940:	f426                	sd	s1,40(sp)
    80004942:	f04a                	sd	s2,32(sp)
    80004944:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004946:	00027497          	auipc	s1,0x27
    8000494a:	efa48493          	addi	s1,s1,-262 # 8002b840 <log>
    8000494e:	8526                	mv	a0,s1
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	2e8080e7          	jalr	744(ra) # 80000c38 <acquire>
  log.outstanding -= 1;
    80004958:	509c                	lw	a5,32(s1)
    8000495a:	37fd                	addiw	a5,a5,-1
    8000495c:	0007891b          	sext.w	s2,a5
    80004960:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004962:	50dc                	lw	a5,36(s1)
    80004964:	e7b9                	bnez	a5,800049b2 <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    80004966:	06091163          	bnez	s2,800049c8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000496a:	00027497          	auipc	s1,0x27
    8000496e:	ed648493          	addi	s1,s1,-298 # 8002b840 <log>
    80004972:	4785                	li	a5,1
    80004974:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004976:	8526                	mv	a0,s1
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	374080e7          	jalr	884(ra) # 80000cec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004980:	54dc                	lw	a5,44(s1)
    80004982:	06f04763          	bgtz	a5,800049f0 <end_op+0xb6>
    acquire(&log.lock);
    80004986:	00027497          	auipc	s1,0x27
    8000498a:	eba48493          	addi	s1,s1,-326 # 8002b840 <log>
    8000498e:	8526                	mv	a0,s1
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	2a8080e7          	jalr	680(ra) # 80000c38 <acquire>
    log.committing = 0;
    80004998:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffffe097          	auipc	ra,0xffffe
    800049a2:	baa080e7          	jalr	-1110(ra) # 80002548 <wakeup>
    release(&log.lock);
    800049a6:	8526                	mv	a0,s1
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	344080e7          	jalr	836(ra) # 80000cec <release>
}
    800049b0:	a815                	j	800049e4 <end_op+0xaa>
    800049b2:	ec4e                	sd	s3,24(sp)
    800049b4:	e852                	sd	s4,16(sp)
    800049b6:	e456                	sd	s5,8(sp)
    panic("log.committing");
    800049b8:	00004517          	auipc	a0,0x4
    800049bc:	b6050513          	addi	a0,a0,-1184 # 80008518 <etext+0x518>
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	ba0080e7          	jalr	-1120(ra) # 80000560 <panic>
    wakeup(&log);
    800049c8:	00027497          	auipc	s1,0x27
    800049cc:	e7848493          	addi	s1,s1,-392 # 8002b840 <log>
    800049d0:	8526                	mv	a0,s1
    800049d2:	ffffe097          	auipc	ra,0xffffe
    800049d6:	b76080e7          	jalr	-1162(ra) # 80002548 <wakeup>
  release(&log.lock);
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	310080e7          	jalr	784(ra) # 80000cec <release>
}
    800049e4:	70e2                	ld	ra,56(sp)
    800049e6:	7442                	ld	s0,48(sp)
    800049e8:	74a2                	ld	s1,40(sp)
    800049ea:	7902                	ld	s2,32(sp)
    800049ec:	6121                	addi	sp,sp,64
    800049ee:	8082                	ret
    800049f0:	ec4e                	sd	s3,24(sp)
    800049f2:	e852                	sd	s4,16(sp)
    800049f4:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    800049f6:	00027a97          	auipc	s5,0x27
    800049fa:	e7aa8a93          	addi	s5,s5,-390 # 8002b870 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049fe:	00027a17          	auipc	s4,0x27
    80004a02:	e42a0a13          	addi	s4,s4,-446 # 8002b840 <log>
    80004a06:	018a2583          	lw	a1,24(s4)
    80004a0a:	012585bb          	addw	a1,a1,s2
    80004a0e:	2585                	addiw	a1,a1,1
    80004a10:	028a2503          	lw	a0,40(s4)
    80004a14:	fffff097          	auipc	ra,0xfffff
    80004a18:	caa080e7          	jalr	-854(ra) # 800036be <bread>
    80004a1c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a1e:	000aa583          	lw	a1,0(s5)
    80004a22:	028a2503          	lw	a0,40(s4)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	c98080e7          	jalr	-872(ra) # 800036be <bread>
    80004a2e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a30:	40000613          	li	a2,1024
    80004a34:	05850593          	addi	a1,a0,88
    80004a38:	05848513          	addi	a0,s1,88
    80004a3c:	ffffc097          	auipc	ra,0xffffc
    80004a40:	354080e7          	jalr	852(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    80004a44:	8526                	mv	a0,s1
    80004a46:	fffff097          	auipc	ra,0xfffff
    80004a4a:	d6a080e7          	jalr	-662(ra) # 800037b0 <bwrite>
    brelse(from);
    80004a4e:	854e                	mv	a0,s3
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	d9e080e7          	jalr	-610(ra) # 800037ee <brelse>
    brelse(to);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	d94080e7          	jalr	-620(ra) # 800037ee <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a62:	2905                	addiw	s2,s2,1
    80004a64:	0a91                	addi	s5,s5,4
    80004a66:	02ca2783          	lw	a5,44(s4)
    80004a6a:	f8f94ee3          	blt	s2,a5,80004a06 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	c8c080e7          	jalr	-884(ra) # 800046fa <write_head>
    install_trans(0); // Now install writes to home locations
    80004a76:	4501                	li	a0,0
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	cec080e7          	jalr	-788(ra) # 80004764 <install_trans>
    log.lh.n = 0;
    80004a80:	00027797          	auipc	a5,0x27
    80004a84:	de07a623          	sw	zero,-532(a5) # 8002b86c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	c72080e7          	jalr	-910(ra) # 800046fa <write_head>
    80004a90:	69e2                	ld	s3,24(sp)
    80004a92:	6a42                	ld	s4,16(sp)
    80004a94:	6aa2                	ld	s5,8(sp)
    80004a96:	bdc5                	j	80004986 <end_op+0x4c>

0000000080004a98 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a98:	1101                	addi	sp,sp,-32
    80004a9a:	ec06                	sd	ra,24(sp)
    80004a9c:	e822                	sd	s0,16(sp)
    80004a9e:	e426                	sd	s1,8(sp)
    80004aa0:	e04a                	sd	s2,0(sp)
    80004aa2:	1000                	addi	s0,sp,32
    80004aa4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004aa6:	00027917          	auipc	s2,0x27
    80004aaa:	d9a90913          	addi	s2,s2,-614 # 8002b840 <log>
    80004aae:	854a                	mv	a0,s2
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	188080e7          	jalr	392(ra) # 80000c38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ab8:	02c92603          	lw	a2,44(s2)
    80004abc:	47f5                	li	a5,29
    80004abe:	06c7c563          	blt	a5,a2,80004b28 <log_write+0x90>
    80004ac2:	00027797          	auipc	a5,0x27
    80004ac6:	d9a7a783          	lw	a5,-614(a5) # 8002b85c <log+0x1c>
    80004aca:	37fd                	addiw	a5,a5,-1
    80004acc:	04f65e63          	bge	a2,a5,80004b28 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ad0:	00027797          	auipc	a5,0x27
    80004ad4:	d907a783          	lw	a5,-624(a5) # 8002b860 <log+0x20>
    80004ad8:	06f05063          	blez	a5,80004b38 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004adc:	4781                	li	a5,0
    80004ade:	06c05563          	blez	a2,80004b48 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ae2:	44cc                	lw	a1,12(s1)
    80004ae4:	00027717          	auipc	a4,0x27
    80004ae8:	d8c70713          	addi	a4,a4,-628 # 8002b870 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004aec:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004aee:	4314                	lw	a3,0(a4)
    80004af0:	04b68c63          	beq	a3,a1,80004b48 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004af4:	2785                	addiw	a5,a5,1
    80004af6:	0711                	addi	a4,a4,4
    80004af8:	fef61be3          	bne	a2,a5,80004aee <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004afc:	0621                	addi	a2,a2,8
    80004afe:	060a                	slli	a2,a2,0x2
    80004b00:	00027797          	auipc	a5,0x27
    80004b04:	d4078793          	addi	a5,a5,-704 # 8002b840 <log>
    80004b08:	97b2                	add	a5,a5,a2
    80004b0a:	44d8                	lw	a4,12(s1)
    80004b0c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b0e:	8526                	mv	a0,s1
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	d7a080e7          	jalr	-646(ra) # 8000388a <bpin>
    log.lh.n++;
    80004b18:	00027717          	auipc	a4,0x27
    80004b1c:	d2870713          	addi	a4,a4,-728 # 8002b840 <log>
    80004b20:	575c                	lw	a5,44(a4)
    80004b22:	2785                	addiw	a5,a5,1
    80004b24:	d75c                	sw	a5,44(a4)
    80004b26:	a82d                	j	80004b60 <log_write+0xc8>
    panic("too big a transaction");
    80004b28:	00004517          	auipc	a0,0x4
    80004b2c:	a0050513          	addi	a0,a0,-1536 # 80008528 <etext+0x528>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	a30080e7          	jalr	-1488(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    80004b38:	00004517          	auipc	a0,0x4
    80004b3c:	a0850513          	addi	a0,a0,-1528 # 80008540 <etext+0x540>
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	a20080e7          	jalr	-1504(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    80004b48:	00878693          	addi	a3,a5,8
    80004b4c:	068a                	slli	a3,a3,0x2
    80004b4e:	00027717          	auipc	a4,0x27
    80004b52:	cf270713          	addi	a4,a4,-782 # 8002b840 <log>
    80004b56:	9736                	add	a4,a4,a3
    80004b58:	44d4                	lw	a3,12(s1)
    80004b5a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b5c:	faf609e3          	beq	a2,a5,80004b0e <log_write+0x76>
  }
  release(&log.lock);
    80004b60:	00027517          	auipc	a0,0x27
    80004b64:	ce050513          	addi	a0,a0,-800 # 8002b840 <log>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	184080e7          	jalr	388(ra) # 80000cec <release>
}
    80004b70:	60e2                	ld	ra,24(sp)
    80004b72:	6442                	ld	s0,16(sp)
    80004b74:	64a2                	ld	s1,8(sp)
    80004b76:	6902                	ld	s2,0(sp)
    80004b78:	6105                	addi	sp,sp,32
    80004b7a:	8082                	ret

0000000080004b7c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b7c:	1101                	addi	sp,sp,-32
    80004b7e:	ec06                	sd	ra,24(sp)
    80004b80:	e822                	sd	s0,16(sp)
    80004b82:	e426                	sd	s1,8(sp)
    80004b84:	e04a                	sd	s2,0(sp)
    80004b86:	1000                	addi	s0,sp,32
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b8c:	00004597          	auipc	a1,0x4
    80004b90:	9d458593          	addi	a1,a1,-1580 # 80008560 <etext+0x560>
    80004b94:	0521                	addi	a0,a0,8
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	012080e7          	jalr	18(ra) # 80000ba8 <initlock>
  lk->name = name;
    80004b9e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ba2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ba6:	0204a423          	sw	zero,40(s1)
}
    80004baa:	60e2                	ld	ra,24(sp)
    80004bac:	6442                	ld	s0,16(sp)
    80004bae:	64a2                	ld	s1,8(sp)
    80004bb0:	6902                	ld	s2,0(sp)
    80004bb2:	6105                	addi	sp,sp,32
    80004bb4:	8082                	ret

0000000080004bb6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004bb6:	1101                	addi	sp,sp,-32
    80004bb8:	ec06                	sd	ra,24(sp)
    80004bba:	e822                	sd	s0,16(sp)
    80004bbc:	e426                	sd	s1,8(sp)
    80004bbe:	e04a                	sd	s2,0(sp)
    80004bc0:	1000                	addi	s0,sp,32
    80004bc2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bc4:	00850913          	addi	s2,a0,8
    80004bc8:	854a                	mv	a0,s2
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	06e080e7          	jalr	110(ra) # 80000c38 <acquire>
  while (lk->locked) {
    80004bd2:	409c                	lw	a5,0(s1)
    80004bd4:	cb89                	beqz	a5,80004be6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bd6:	85ca                	mv	a1,s2
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffe097          	auipc	ra,0xffffe
    80004bde:	90a080e7          	jalr	-1782(ra) # 800024e4 <sleep>
  while (lk->locked) {
    80004be2:	409c                	lw	a5,0(s1)
    80004be4:	fbed                	bnez	a5,80004bd6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004be6:	4785                	li	a5,1
    80004be8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	e90080e7          	jalr	-368(ra) # 80001a7a <myproc>
    80004bf2:	591c                	lw	a5,48(a0)
    80004bf4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bf6:	854a                	mv	a0,s2
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	0f4080e7          	jalr	244(ra) # 80000cec <release>
}
    80004c00:	60e2                	ld	ra,24(sp)
    80004c02:	6442                	ld	s0,16(sp)
    80004c04:	64a2                	ld	s1,8(sp)
    80004c06:	6902                	ld	s2,0(sp)
    80004c08:	6105                	addi	sp,sp,32
    80004c0a:	8082                	ret

0000000080004c0c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c0c:	1101                	addi	sp,sp,-32
    80004c0e:	ec06                	sd	ra,24(sp)
    80004c10:	e822                	sd	s0,16(sp)
    80004c12:	e426                	sd	s1,8(sp)
    80004c14:	e04a                	sd	s2,0(sp)
    80004c16:	1000                	addi	s0,sp,32
    80004c18:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c1a:	00850913          	addi	s2,a0,8
    80004c1e:	854a                	mv	a0,s2
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	018080e7          	jalr	24(ra) # 80000c38 <acquire>
  lk->locked = 0;
    80004c28:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c2c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffe097          	auipc	ra,0xffffe
    80004c36:	916080e7          	jalr	-1770(ra) # 80002548 <wakeup>
  release(&lk->lk);
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	0b0080e7          	jalr	176(ra) # 80000cec <release>
}
    80004c44:	60e2                	ld	ra,24(sp)
    80004c46:	6442                	ld	s0,16(sp)
    80004c48:	64a2                	ld	s1,8(sp)
    80004c4a:	6902                	ld	s2,0(sp)
    80004c4c:	6105                	addi	sp,sp,32
    80004c4e:	8082                	ret

0000000080004c50 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c50:	7179                	addi	sp,sp,-48
    80004c52:	f406                	sd	ra,40(sp)
    80004c54:	f022                	sd	s0,32(sp)
    80004c56:	ec26                	sd	s1,24(sp)
    80004c58:	e84a                	sd	s2,16(sp)
    80004c5a:	1800                	addi	s0,sp,48
    80004c5c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c5e:	00850913          	addi	s2,a0,8
    80004c62:	854a                	mv	a0,s2
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	fd4080e7          	jalr	-44(ra) # 80000c38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c6c:	409c                	lw	a5,0(s1)
    80004c6e:	ef91                	bnez	a5,80004c8a <holdingsleep+0x3a>
    80004c70:	4481                	li	s1,0
  release(&lk->lk);
    80004c72:	854a                	mv	a0,s2
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	078080e7          	jalr	120(ra) # 80000cec <release>
  return r;
}
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	70a2                	ld	ra,40(sp)
    80004c80:	7402                	ld	s0,32(sp)
    80004c82:	64e2                	ld	s1,24(sp)
    80004c84:	6942                	ld	s2,16(sp)
    80004c86:	6145                	addi	sp,sp,48
    80004c88:	8082                	ret
    80004c8a:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c8c:	0284a983          	lw	s3,40(s1)
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	dea080e7          	jalr	-534(ra) # 80001a7a <myproc>
    80004c98:	5904                	lw	s1,48(a0)
    80004c9a:	413484b3          	sub	s1,s1,s3
    80004c9e:	0014b493          	seqz	s1,s1
    80004ca2:	69a2                	ld	s3,8(sp)
    80004ca4:	b7f9                	j	80004c72 <holdingsleep+0x22>

0000000080004ca6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ca6:	1141                	addi	sp,sp,-16
    80004ca8:	e406                	sd	ra,8(sp)
    80004caa:	e022                	sd	s0,0(sp)
    80004cac:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cae:	00004597          	auipc	a1,0x4
    80004cb2:	8c258593          	addi	a1,a1,-1854 # 80008570 <etext+0x570>
    80004cb6:	00027517          	auipc	a0,0x27
    80004cba:	cd250513          	addi	a0,a0,-814 # 8002b988 <ftable>
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	eea080e7          	jalr	-278(ra) # 80000ba8 <initlock>
}
    80004cc6:	60a2                	ld	ra,8(sp)
    80004cc8:	6402                	ld	s0,0(sp)
    80004cca:	0141                	addi	sp,sp,16
    80004ccc:	8082                	ret

0000000080004cce <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cce:	1101                	addi	sp,sp,-32
    80004cd0:	ec06                	sd	ra,24(sp)
    80004cd2:	e822                	sd	s0,16(sp)
    80004cd4:	e426                	sd	s1,8(sp)
    80004cd6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cd8:	00027517          	auipc	a0,0x27
    80004cdc:	cb050513          	addi	a0,a0,-848 # 8002b988 <ftable>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	f58080e7          	jalr	-168(ra) # 80000c38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ce8:	00027497          	auipc	s1,0x27
    80004cec:	cb848493          	addi	s1,s1,-840 # 8002b9a0 <ftable+0x18>
    80004cf0:	00028717          	auipc	a4,0x28
    80004cf4:	c5070713          	addi	a4,a4,-944 # 8002c940 <disk>
    if(f->ref == 0){
    80004cf8:	40dc                	lw	a5,4(s1)
    80004cfa:	cf99                	beqz	a5,80004d18 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cfc:	02848493          	addi	s1,s1,40
    80004d00:	fee49ce3          	bne	s1,a4,80004cf8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d04:	00027517          	auipc	a0,0x27
    80004d08:	c8450513          	addi	a0,a0,-892 # 8002b988 <ftable>
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	fe0080e7          	jalr	-32(ra) # 80000cec <release>
  return 0;
    80004d14:	4481                	li	s1,0
    80004d16:	a819                	j	80004d2c <filealloc+0x5e>
      f->ref = 1;
    80004d18:	4785                	li	a5,1
    80004d1a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d1c:	00027517          	auipc	a0,0x27
    80004d20:	c6c50513          	addi	a0,a0,-916 # 8002b988 <ftable>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	fc8080e7          	jalr	-56(ra) # 80000cec <release>
}
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	60e2                	ld	ra,24(sp)
    80004d30:	6442                	ld	s0,16(sp)
    80004d32:	64a2                	ld	s1,8(sp)
    80004d34:	6105                	addi	sp,sp,32
    80004d36:	8082                	ret

0000000080004d38 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d38:	1101                	addi	sp,sp,-32
    80004d3a:	ec06                	sd	ra,24(sp)
    80004d3c:	e822                	sd	s0,16(sp)
    80004d3e:	e426                	sd	s1,8(sp)
    80004d40:	1000                	addi	s0,sp,32
    80004d42:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d44:	00027517          	auipc	a0,0x27
    80004d48:	c4450513          	addi	a0,a0,-956 # 8002b988 <ftable>
    80004d4c:	ffffc097          	auipc	ra,0xffffc
    80004d50:	eec080e7          	jalr	-276(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004d54:	40dc                	lw	a5,4(s1)
    80004d56:	02f05263          	blez	a5,80004d7a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d5a:	2785                	addiw	a5,a5,1
    80004d5c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d5e:	00027517          	auipc	a0,0x27
    80004d62:	c2a50513          	addi	a0,a0,-982 # 8002b988 <ftable>
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	f86080e7          	jalr	-122(ra) # 80000cec <release>
  return f;
}
    80004d6e:	8526                	mv	a0,s1
    80004d70:	60e2                	ld	ra,24(sp)
    80004d72:	6442                	ld	s0,16(sp)
    80004d74:	64a2                	ld	s1,8(sp)
    80004d76:	6105                	addi	sp,sp,32
    80004d78:	8082                	ret
    panic("filedup");
    80004d7a:	00003517          	auipc	a0,0x3
    80004d7e:	7fe50513          	addi	a0,a0,2046 # 80008578 <etext+0x578>
    80004d82:	ffffb097          	auipc	ra,0xffffb
    80004d86:	7de080e7          	jalr	2014(ra) # 80000560 <panic>

0000000080004d8a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d8a:	7139                	addi	sp,sp,-64
    80004d8c:	fc06                	sd	ra,56(sp)
    80004d8e:	f822                	sd	s0,48(sp)
    80004d90:	f426                	sd	s1,40(sp)
    80004d92:	0080                	addi	s0,sp,64
    80004d94:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d96:	00027517          	auipc	a0,0x27
    80004d9a:	bf250513          	addi	a0,a0,-1038 # 8002b988 <ftable>
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	e9a080e7          	jalr	-358(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004da6:	40dc                	lw	a5,4(s1)
    80004da8:	04f05c63          	blez	a5,80004e00 <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80004dac:	37fd                	addiw	a5,a5,-1
    80004dae:	0007871b          	sext.w	a4,a5
    80004db2:	c0dc                	sw	a5,4(s1)
    80004db4:	06e04263          	bgtz	a4,80004e18 <fileclose+0x8e>
    80004db8:	f04a                	sd	s2,32(sp)
    80004dba:	ec4e                	sd	s3,24(sp)
    80004dbc:	e852                	sd	s4,16(sp)
    80004dbe:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004dc0:	0004a903          	lw	s2,0(s1)
    80004dc4:	0094ca83          	lbu	s5,9(s1)
    80004dc8:	0104ba03          	ld	s4,16(s1)
    80004dcc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dd0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dd4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004dd8:	00027517          	auipc	a0,0x27
    80004ddc:	bb050513          	addi	a0,a0,-1104 # 8002b988 <ftable>
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	f0c080e7          	jalr	-244(ra) # 80000cec <release>

  if(ff.type == FD_PIPE){
    80004de8:	4785                	li	a5,1
    80004dea:	04f90463          	beq	s2,a5,80004e32 <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dee:	3979                	addiw	s2,s2,-2
    80004df0:	4785                	li	a5,1
    80004df2:	0527fb63          	bgeu	a5,s2,80004e48 <fileclose+0xbe>
    80004df6:	7902                	ld	s2,32(sp)
    80004df8:	69e2                	ld	s3,24(sp)
    80004dfa:	6a42                	ld	s4,16(sp)
    80004dfc:	6aa2                	ld	s5,8(sp)
    80004dfe:	a02d                	j	80004e28 <fileclose+0x9e>
    80004e00:	f04a                	sd	s2,32(sp)
    80004e02:	ec4e                	sd	s3,24(sp)
    80004e04:	e852                	sd	s4,16(sp)
    80004e06:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004e08:	00003517          	auipc	a0,0x3
    80004e0c:	77850513          	addi	a0,a0,1912 # 80008580 <etext+0x580>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	750080e7          	jalr	1872(ra) # 80000560 <panic>
    release(&ftable.lock);
    80004e18:	00027517          	auipc	a0,0x27
    80004e1c:	b7050513          	addi	a0,a0,-1168 # 8002b988 <ftable>
    80004e20:	ffffc097          	auipc	ra,0xffffc
    80004e24:	ecc080e7          	jalr	-308(ra) # 80000cec <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004e28:	70e2                	ld	ra,56(sp)
    80004e2a:	7442                	ld	s0,48(sp)
    80004e2c:	74a2                	ld	s1,40(sp)
    80004e2e:	6121                	addi	sp,sp,64
    80004e30:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e32:	85d6                	mv	a1,s5
    80004e34:	8552                	mv	a0,s4
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	3a2080e7          	jalr	930(ra) # 800051d8 <pipeclose>
    80004e3e:	7902                	ld	s2,32(sp)
    80004e40:	69e2                	ld	s3,24(sp)
    80004e42:	6a42                	ld	s4,16(sp)
    80004e44:	6aa2                	ld	s5,8(sp)
    80004e46:	b7cd                	j	80004e28 <fileclose+0x9e>
    begin_op();
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	a78080e7          	jalr	-1416(ra) # 800048c0 <begin_op>
    iput(ff.ip);
    80004e50:	854e                	mv	a0,s3
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	25e080e7          	jalr	606(ra) # 800040b0 <iput>
    end_op();
    80004e5a:	00000097          	auipc	ra,0x0
    80004e5e:	ae0080e7          	jalr	-1312(ra) # 8000493a <end_op>
    80004e62:	7902                	ld	s2,32(sp)
    80004e64:	69e2                	ld	s3,24(sp)
    80004e66:	6a42                	ld	s4,16(sp)
    80004e68:	6aa2                	ld	s5,8(sp)
    80004e6a:	bf7d                	j	80004e28 <fileclose+0x9e>

0000000080004e6c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e6c:	715d                	addi	sp,sp,-80
    80004e6e:	e486                	sd	ra,72(sp)
    80004e70:	e0a2                	sd	s0,64(sp)
    80004e72:	fc26                	sd	s1,56(sp)
    80004e74:	f44e                	sd	s3,40(sp)
    80004e76:	0880                	addi	s0,sp,80
    80004e78:	84aa                	mv	s1,a0
    80004e7a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	bfe080e7          	jalr	-1026(ra) # 80001a7a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e84:	409c                	lw	a5,0(s1)
    80004e86:	37f9                	addiw	a5,a5,-2
    80004e88:	4705                	li	a4,1
    80004e8a:	04f76863          	bltu	a4,a5,80004eda <filestat+0x6e>
    80004e8e:	f84a                	sd	s2,48(sp)
    80004e90:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e92:	6c88                	ld	a0,24(s1)
    80004e94:	fffff097          	auipc	ra,0xfffff
    80004e98:	05e080e7          	jalr	94(ra) # 80003ef2 <ilock>
    stati(f->ip, &st);
    80004e9c:	fb840593          	addi	a1,s0,-72
    80004ea0:	6c88                	ld	a0,24(s1)
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	2de080e7          	jalr	734(ra) # 80004180 <stati>
    iunlock(f->ip);
    80004eaa:	6c88                	ld	a0,24(s1)
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	10c080e7          	jalr	268(ra) # 80003fb8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004eb4:	46e1                	li	a3,24
    80004eb6:	fb840613          	addi	a2,s0,-72
    80004eba:	85ce                	mv	a1,s3
    80004ebc:	22893503          	ld	a0,552(s2)
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	822080e7          	jalr	-2014(ra) # 800016e2 <copyout>
    80004ec8:	41f5551b          	sraiw	a0,a0,0x1f
    80004ecc:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004ece:	60a6                	ld	ra,72(sp)
    80004ed0:	6406                	ld	s0,64(sp)
    80004ed2:	74e2                	ld	s1,56(sp)
    80004ed4:	79a2                	ld	s3,40(sp)
    80004ed6:	6161                	addi	sp,sp,80
    80004ed8:	8082                	ret
  return -1;
    80004eda:	557d                	li	a0,-1
    80004edc:	bfcd                	j	80004ece <filestat+0x62>

0000000080004ede <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ede:	7179                	addi	sp,sp,-48
    80004ee0:	f406                	sd	ra,40(sp)
    80004ee2:	f022                	sd	s0,32(sp)
    80004ee4:	e84a                	sd	s2,16(sp)
    80004ee6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ee8:	00854783          	lbu	a5,8(a0)
    80004eec:	cbc5                	beqz	a5,80004f9c <fileread+0xbe>
    80004eee:	ec26                	sd	s1,24(sp)
    80004ef0:	e44e                	sd	s3,8(sp)
    80004ef2:	84aa                	mv	s1,a0
    80004ef4:	89ae                	mv	s3,a1
    80004ef6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ef8:	411c                	lw	a5,0(a0)
    80004efa:	4705                	li	a4,1
    80004efc:	04e78963          	beq	a5,a4,80004f4e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f00:	470d                	li	a4,3
    80004f02:	04e78f63          	beq	a5,a4,80004f60 <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f06:	4709                	li	a4,2
    80004f08:	08e79263          	bne	a5,a4,80004f8c <fileread+0xae>
    ilock(f->ip);
    80004f0c:	6d08                	ld	a0,24(a0)
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	fe4080e7          	jalr	-28(ra) # 80003ef2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f16:	874a                	mv	a4,s2
    80004f18:	5094                	lw	a3,32(s1)
    80004f1a:	864e                	mv	a2,s3
    80004f1c:	4585                	li	a1,1
    80004f1e:	6c88                	ld	a0,24(s1)
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	28a080e7          	jalr	650(ra) # 800041aa <readi>
    80004f28:	892a                	mv	s2,a0
    80004f2a:	00a05563          	blez	a0,80004f34 <fileread+0x56>
      f->off += r;
    80004f2e:	509c                	lw	a5,32(s1)
    80004f30:	9fa9                	addw	a5,a5,a0
    80004f32:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f34:	6c88                	ld	a0,24(s1)
    80004f36:	fffff097          	auipc	ra,0xfffff
    80004f3a:	082080e7          	jalr	130(ra) # 80003fb8 <iunlock>
    80004f3e:	64e2                	ld	s1,24(sp)
    80004f40:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004f42:	854a                	mv	a0,s2
    80004f44:	70a2                	ld	ra,40(sp)
    80004f46:	7402                	ld	s0,32(sp)
    80004f48:	6942                	ld	s2,16(sp)
    80004f4a:	6145                	addi	sp,sp,48
    80004f4c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f4e:	6908                	ld	a0,16(a0)
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	400080e7          	jalr	1024(ra) # 80005350 <piperead>
    80004f58:	892a                	mv	s2,a0
    80004f5a:	64e2                	ld	s1,24(sp)
    80004f5c:	69a2                	ld	s3,8(sp)
    80004f5e:	b7d5                	j	80004f42 <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f60:	02451783          	lh	a5,36(a0)
    80004f64:	03079693          	slli	a3,a5,0x30
    80004f68:	92c1                	srli	a3,a3,0x30
    80004f6a:	4725                	li	a4,9
    80004f6c:	02d76a63          	bltu	a4,a3,80004fa0 <fileread+0xc2>
    80004f70:	0792                	slli	a5,a5,0x4
    80004f72:	00027717          	auipc	a4,0x27
    80004f76:	97670713          	addi	a4,a4,-1674 # 8002b8e8 <devsw>
    80004f7a:	97ba                	add	a5,a5,a4
    80004f7c:	639c                	ld	a5,0(a5)
    80004f7e:	c78d                	beqz	a5,80004fa8 <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    80004f80:	4505                	li	a0,1
    80004f82:	9782                	jalr	a5
    80004f84:	892a                	mv	s2,a0
    80004f86:	64e2                	ld	s1,24(sp)
    80004f88:	69a2                	ld	s3,8(sp)
    80004f8a:	bf65                	j	80004f42 <fileread+0x64>
    panic("fileread");
    80004f8c:	00003517          	auipc	a0,0x3
    80004f90:	60450513          	addi	a0,a0,1540 # 80008590 <etext+0x590>
    80004f94:	ffffb097          	auipc	ra,0xffffb
    80004f98:	5cc080e7          	jalr	1484(ra) # 80000560 <panic>
    return -1;
    80004f9c:	597d                	li	s2,-1
    80004f9e:	b755                	j	80004f42 <fileread+0x64>
      return -1;
    80004fa0:	597d                	li	s2,-1
    80004fa2:	64e2                	ld	s1,24(sp)
    80004fa4:	69a2                	ld	s3,8(sp)
    80004fa6:	bf71                	j	80004f42 <fileread+0x64>
    80004fa8:	597d                	li	s2,-1
    80004faa:	64e2                	ld	s1,24(sp)
    80004fac:	69a2                	ld	s3,8(sp)
    80004fae:	bf51                	j	80004f42 <fileread+0x64>

0000000080004fb0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004fb0:	00954783          	lbu	a5,9(a0)
    80004fb4:	12078963          	beqz	a5,800050e6 <filewrite+0x136>
{
    80004fb8:	715d                	addi	sp,sp,-80
    80004fba:	e486                	sd	ra,72(sp)
    80004fbc:	e0a2                	sd	s0,64(sp)
    80004fbe:	f84a                	sd	s2,48(sp)
    80004fc0:	f052                	sd	s4,32(sp)
    80004fc2:	e85a                	sd	s6,16(sp)
    80004fc4:	0880                	addi	s0,sp,80
    80004fc6:	892a                	mv	s2,a0
    80004fc8:	8b2e                	mv	s6,a1
    80004fca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fcc:	411c                	lw	a5,0(a0)
    80004fce:	4705                	li	a4,1
    80004fd0:	02e78763          	beq	a5,a4,80004ffe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fd4:	470d                	li	a4,3
    80004fd6:	02e78a63          	beq	a5,a4,8000500a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fda:	4709                	li	a4,2
    80004fdc:	0ee79863          	bne	a5,a4,800050cc <filewrite+0x11c>
    80004fe0:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fe2:	0cc05463          	blez	a2,800050aa <filewrite+0xfa>
    80004fe6:	fc26                	sd	s1,56(sp)
    80004fe8:	ec56                	sd	s5,24(sp)
    80004fea:	e45e                	sd	s7,8(sp)
    80004fec:	e062                	sd	s8,0(sp)
    int i = 0;
    80004fee:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004ff0:	6b85                	lui	s7,0x1
    80004ff2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ff6:	6c05                	lui	s8,0x1
    80004ff8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004ffc:	a851                	j	80005090 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004ffe:	6908                	ld	a0,16(a0)
    80005000:	00000097          	auipc	ra,0x0
    80005004:	248080e7          	jalr	584(ra) # 80005248 <pipewrite>
    80005008:	a85d                	j	800050be <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000500a:	02451783          	lh	a5,36(a0)
    8000500e:	03079693          	slli	a3,a5,0x30
    80005012:	92c1                	srli	a3,a3,0x30
    80005014:	4725                	li	a4,9
    80005016:	0cd76a63          	bltu	a4,a3,800050ea <filewrite+0x13a>
    8000501a:	0792                	slli	a5,a5,0x4
    8000501c:	00027717          	auipc	a4,0x27
    80005020:	8cc70713          	addi	a4,a4,-1844 # 8002b8e8 <devsw>
    80005024:	97ba                	add	a5,a5,a4
    80005026:	679c                	ld	a5,8(a5)
    80005028:	c3f9                	beqz	a5,800050ee <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    8000502a:	4505                	li	a0,1
    8000502c:	9782                	jalr	a5
    8000502e:	a841                	j	800050be <filewrite+0x10e>
      if(n1 > max)
    80005030:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80005034:	00000097          	auipc	ra,0x0
    80005038:	88c080e7          	jalr	-1908(ra) # 800048c0 <begin_op>
      ilock(f->ip);
    8000503c:	01893503          	ld	a0,24(s2)
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	eb2080e7          	jalr	-334(ra) # 80003ef2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005048:	8756                	mv	a4,s5
    8000504a:	02092683          	lw	a3,32(s2)
    8000504e:	01698633          	add	a2,s3,s6
    80005052:	4585                	li	a1,1
    80005054:	01893503          	ld	a0,24(s2)
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	262080e7          	jalr	610(ra) # 800042ba <writei>
    80005060:	84aa                	mv	s1,a0
    80005062:	00a05763          	blez	a0,80005070 <filewrite+0xc0>
        f->off += r;
    80005066:	02092783          	lw	a5,32(s2)
    8000506a:	9fa9                	addw	a5,a5,a0
    8000506c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005070:	01893503          	ld	a0,24(s2)
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	f44080e7          	jalr	-188(ra) # 80003fb8 <iunlock>
      end_op();
    8000507c:	00000097          	auipc	ra,0x0
    80005080:	8be080e7          	jalr	-1858(ra) # 8000493a <end_op>

      if(r != n1){
    80005084:	029a9563          	bne	s5,s1,800050ae <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    80005088:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000508c:	0149da63          	bge	s3,s4,800050a0 <filewrite+0xf0>
      int n1 = n - i;
    80005090:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80005094:	0004879b          	sext.w	a5,s1
    80005098:	f8fbdce3          	bge	s7,a5,80005030 <filewrite+0x80>
    8000509c:	84e2                	mv	s1,s8
    8000509e:	bf49                	j	80005030 <filewrite+0x80>
    800050a0:	74e2                	ld	s1,56(sp)
    800050a2:	6ae2                	ld	s5,24(sp)
    800050a4:	6ba2                	ld	s7,8(sp)
    800050a6:	6c02                	ld	s8,0(sp)
    800050a8:	a039                	j	800050b6 <filewrite+0x106>
    int i = 0;
    800050aa:	4981                	li	s3,0
    800050ac:	a029                	j	800050b6 <filewrite+0x106>
    800050ae:	74e2                	ld	s1,56(sp)
    800050b0:	6ae2                	ld	s5,24(sp)
    800050b2:	6ba2                	ld	s7,8(sp)
    800050b4:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800050b6:	033a1e63          	bne	s4,s3,800050f2 <filewrite+0x142>
    800050ba:	8552                	mv	a0,s4
    800050bc:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050be:	60a6                	ld	ra,72(sp)
    800050c0:	6406                	ld	s0,64(sp)
    800050c2:	7942                	ld	s2,48(sp)
    800050c4:	7a02                	ld	s4,32(sp)
    800050c6:	6b42                	ld	s6,16(sp)
    800050c8:	6161                	addi	sp,sp,80
    800050ca:	8082                	ret
    800050cc:	fc26                	sd	s1,56(sp)
    800050ce:	f44e                	sd	s3,40(sp)
    800050d0:	ec56                	sd	s5,24(sp)
    800050d2:	e45e                	sd	s7,8(sp)
    800050d4:	e062                	sd	s8,0(sp)
    panic("filewrite");
    800050d6:	00003517          	auipc	a0,0x3
    800050da:	4ca50513          	addi	a0,a0,1226 # 800085a0 <etext+0x5a0>
    800050de:	ffffb097          	auipc	ra,0xffffb
    800050e2:	482080e7          	jalr	1154(ra) # 80000560 <panic>
    return -1;
    800050e6:	557d                	li	a0,-1
}
    800050e8:	8082                	ret
      return -1;
    800050ea:	557d                	li	a0,-1
    800050ec:	bfc9                	j	800050be <filewrite+0x10e>
    800050ee:	557d                	li	a0,-1
    800050f0:	b7f9                	j	800050be <filewrite+0x10e>
    ret = (i == n ? n : -1);
    800050f2:	557d                	li	a0,-1
    800050f4:	79a2                	ld	s3,40(sp)
    800050f6:	b7e1                	j	800050be <filewrite+0x10e>

00000000800050f8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050f8:	7179                	addi	sp,sp,-48
    800050fa:	f406                	sd	ra,40(sp)
    800050fc:	f022                	sd	s0,32(sp)
    800050fe:	ec26                	sd	s1,24(sp)
    80005100:	e052                	sd	s4,0(sp)
    80005102:	1800                	addi	s0,sp,48
    80005104:	84aa                	mv	s1,a0
    80005106:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005108:	0005b023          	sd	zero,0(a1)
    8000510c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005110:	00000097          	auipc	ra,0x0
    80005114:	bbe080e7          	jalr	-1090(ra) # 80004cce <filealloc>
    80005118:	e088                	sd	a0,0(s1)
    8000511a:	cd49                	beqz	a0,800051b4 <pipealloc+0xbc>
    8000511c:	00000097          	auipc	ra,0x0
    80005120:	bb2080e7          	jalr	-1102(ra) # 80004cce <filealloc>
    80005124:	00aa3023          	sd	a0,0(s4)
    80005128:	c141                	beqz	a0,800051a8 <pipealloc+0xb0>
    8000512a:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	a1c080e7          	jalr	-1508(ra) # 80000b48 <kalloc>
    80005134:	892a                	mv	s2,a0
    80005136:	c13d                	beqz	a0,8000519c <pipealloc+0xa4>
    80005138:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    8000513a:	4985                	li	s3,1
    8000513c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005140:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005144:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005148:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000514c:	00003597          	auipc	a1,0x3
    80005150:	46458593          	addi	a1,a1,1124 # 800085b0 <etext+0x5b0>
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	a54080e7          	jalr	-1452(ra) # 80000ba8 <initlock>
  (*f0)->type = FD_PIPE;
    8000515c:	609c                	ld	a5,0(s1)
    8000515e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005162:	609c                	ld	a5,0(s1)
    80005164:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005168:	609c                	ld	a5,0(s1)
    8000516a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000516e:	609c                	ld	a5,0(s1)
    80005170:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005174:	000a3783          	ld	a5,0(s4)
    80005178:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000517c:	000a3783          	ld	a5,0(s4)
    80005180:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005184:	000a3783          	ld	a5,0(s4)
    80005188:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000518c:	000a3783          	ld	a5,0(s4)
    80005190:	0127b823          	sd	s2,16(a5)
  return 0;
    80005194:	4501                	li	a0,0
    80005196:	6942                	ld	s2,16(sp)
    80005198:	69a2                	ld	s3,8(sp)
    8000519a:	a03d                	j	800051c8 <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000519c:	6088                	ld	a0,0(s1)
    8000519e:	c119                	beqz	a0,800051a4 <pipealloc+0xac>
    800051a0:	6942                	ld	s2,16(sp)
    800051a2:	a029                	j	800051ac <pipealloc+0xb4>
    800051a4:	6942                	ld	s2,16(sp)
    800051a6:	a039                	j	800051b4 <pipealloc+0xbc>
    800051a8:	6088                	ld	a0,0(s1)
    800051aa:	c50d                	beqz	a0,800051d4 <pipealloc+0xdc>
    fileclose(*f0);
    800051ac:	00000097          	auipc	ra,0x0
    800051b0:	bde080e7          	jalr	-1058(ra) # 80004d8a <fileclose>
  if(*f1)
    800051b4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051b8:	557d                	li	a0,-1
  if(*f1)
    800051ba:	c799                	beqz	a5,800051c8 <pipealloc+0xd0>
    fileclose(*f1);
    800051bc:	853e                	mv	a0,a5
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	bcc080e7          	jalr	-1076(ra) # 80004d8a <fileclose>
  return -1;
    800051c6:	557d                	li	a0,-1
}
    800051c8:	70a2                	ld	ra,40(sp)
    800051ca:	7402                	ld	s0,32(sp)
    800051cc:	64e2                	ld	s1,24(sp)
    800051ce:	6a02                	ld	s4,0(sp)
    800051d0:	6145                	addi	sp,sp,48
    800051d2:	8082                	ret
  return -1;
    800051d4:	557d                	li	a0,-1
    800051d6:	bfcd                	j	800051c8 <pipealloc+0xd0>

00000000800051d8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051d8:	1101                	addi	sp,sp,-32
    800051da:	ec06                	sd	ra,24(sp)
    800051dc:	e822                	sd	s0,16(sp)
    800051de:	e426                	sd	s1,8(sp)
    800051e0:	e04a                	sd	s2,0(sp)
    800051e2:	1000                	addi	s0,sp,32
    800051e4:	84aa                	mv	s1,a0
    800051e6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	a50080e7          	jalr	-1456(ra) # 80000c38 <acquire>
  if(writable){
    800051f0:	02090d63          	beqz	s2,8000522a <pipeclose+0x52>
    pi->writeopen = 0;
    800051f4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051f8:	21848513          	addi	a0,s1,536
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	34c080e7          	jalr	844(ra) # 80002548 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005204:	2204b783          	ld	a5,544(s1)
    80005208:	eb95                	bnez	a5,8000523c <pipeclose+0x64>
    release(&pi->lock);
    8000520a:	8526                	mv	a0,s1
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	ae0080e7          	jalr	-1312(ra) # 80000cec <release>
    kfree((char*)pi);
    80005214:	8526                	mv	a0,s1
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	834080e7          	jalr	-1996(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    8000521e:	60e2                	ld	ra,24(sp)
    80005220:	6442                	ld	s0,16(sp)
    80005222:	64a2                	ld	s1,8(sp)
    80005224:	6902                	ld	s2,0(sp)
    80005226:	6105                	addi	sp,sp,32
    80005228:	8082                	ret
    pi->readopen = 0;
    8000522a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000522e:	21c48513          	addi	a0,s1,540
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	316080e7          	jalr	790(ra) # 80002548 <wakeup>
    8000523a:	b7e9                	j	80005204 <pipeclose+0x2c>
    release(&pi->lock);
    8000523c:	8526                	mv	a0,s1
    8000523e:	ffffc097          	auipc	ra,0xffffc
    80005242:	aae080e7          	jalr	-1362(ra) # 80000cec <release>
}
    80005246:	bfe1                	j	8000521e <pipeclose+0x46>

0000000080005248 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005248:	711d                	addi	sp,sp,-96
    8000524a:	ec86                	sd	ra,88(sp)
    8000524c:	e8a2                	sd	s0,80(sp)
    8000524e:	e4a6                	sd	s1,72(sp)
    80005250:	e0ca                	sd	s2,64(sp)
    80005252:	fc4e                	sd	s3,56(sp)
    80005254:	f852                	sd	s4,48(sp)
    80005256:	f456                	sd	s5,40(sp)
    80005258:	1080                	addi	s0,sp,96
    8000525a:	84aa                	mv	s1,a0
    8000525c:	8aae                	mv	s5,a1
    8000525e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	81a080e7          	jalr	-2022(ra) # 80001a7a <myproc>
    80005268:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000526a:	8526                	mv	a0,s1
    8000526c:	ffffc097          	auipc	ra,0xffffc
    80005270:	9cc080e7          	jalr	-1588(ra) # 80000c38 <acquire>
  while(i < n){
    80005274:	0d405863          	blez	s4,80005344 <pipewrite+0xfc>
    80005278:	f05a                	sd	s6,32(sp)
    8000527a:	ec5e                	sd	s7,24(sp)
    8000527c:	e862                	sd	s8,16(sp)
  int i = 0;
    8000527e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005280:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005282:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005286:	21c48b93          	addi	s7,s1,540
    8000528a:	a089                	j	800052cc <pipewrite+0x84>
      release(&pi->lock);
    8000528c:	8526                	mv	a0,s1
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	a5e080e7          	jalr	-1442(ra) # 80000cec <release>
      return -1;
    80005296:	597d                	li	s2,-1
    80005298:	7b02                	ld	s6,32(sp)
    8000529a:	6be2                	ld	s7,24(sp)
    8000529c:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000529e:	854a                	mv	a0,s2
    800052a0:	60e6                	ld	ra,88(sp)
    800052a2:	6446                	ld	s0,80(sp)
    800052a4:	64a6                	ld	s1,72(sp)
    800052a6:	6906                	ld	s2,64(sp)
    800052a8:	79e2                	ld	s3,56(sp)
    800052aa:	7a42                	ld	s4,48(sp)
    800052ac:	7aa2                	ld	s5,40(sp)
    800052ae:	6125                	addi	sp,sp,96
    800052b0:	8082                	ret
      wakeup(&pi->nread);
    800052b2:	8562                	mv	a0,s8
    800052b4:	ffffd097          	auipc	ra,0xffffd
    800052b8:	294080e7          	jalr	660(ra) # 80002548 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052bc:	85a6                	mv	a1,s1
    800052be:	855e                	mv	a0,s7
    800052c0:	ffffd097          	auipc	ra,0xffffd
    800052c4:	224080e7          	jalr	548(ra) # 800024e4 <sleep>
  while(i < n){
    800052c8:	05495f63          	bge	s2,s4,80005326 <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    800052cc:	2204a783          	lw	a5,544(s1)
    800052d0:	dfd5                	beqz	a5,8000528c <pipewrite+0x44>
    800052d2:	854e                	mv	a0,s3
    800052d4:	ffffd097          	auipc	ra,0xffffd
    800052d8:	4c4080e7          	jalr	1220(ra) # 80002798 <killed>
    800052dc:	f945                	bnez	a0,8000528c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052de:	2184a783          	lw	a5,536(s1)
    800052e2:	21c4a703          	lw	a4,540(s1)
    800052e6:	2007879b          	addiw	a5,a5,512
    800052ea:	fcf704e3          	beq	a4,a5,800052b2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052ee:	4685                	li	a3,1
    800052f0:	01590633          	add	a2,s2,s5
    800052f4:	faf40593          	addi	a1,s0,-81
    800052f8:	2289b503          	ld	a0,552(s3)
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	472080e7          	jalr	1138(ra) # 8000176e <copyin>
    80005304:	05650263          	beq	a0,s6,80005348 <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005308:	21c4a783          	lw	a5,540(s1)
    8000530c:	0017871b          	addiw	a4,a5,1
    80005310:	20e4ae23          	sw	a4,540(s1)
    80005314:	1ff7f793          	andi	a5,a5,511
    80005318:	97a6                	add	a5,a5,s1
    8000531a:	faf44703          	lbu	a4,-81(s0)
    8000531e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005322:	2905                	addiw	s2,s2,1
    80005324:	b755                	j	800052c8 <pipewrite+0x80>
    80005326:	7b02                	ld	s6,32(sp)
    80005328:	6be2                	ld	s7,24(sp)
    8000532a:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    8000532c:	21848513          	addi	a0,s1,536
    80005330:	ffffd097          	auipc	ra,0xffffd
    80005334:	218080e7          	jalr	536(ra) # 80002548 <wakeup>
  release(&pi->lock);
    80005338:	8526                	mv	a0,s1
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	9b2080e7          	jalr	-1614(ra) # 80000cec <release>
  return i;
    80005342:	bfb1                	j	8000529e <pipewrite+0x56>
  int i = 0;
    80005344:	4901                	li	s2,0
    80005346:	b7dd                	j	8000532c <pipewrite+0xe4>
    80005348:	7b02                	ld	s6,32(sp)
    8000534a:	6be2                	ld	s7,24(sp)
    8000534c:	6c42                	ld	s8,16(sp)
    8000534e:	bff9                	j	8000532c <pipewrite+0xe4>

0000000080005350 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005350:	715d                	addi	sp,sp,-80
    80005352:	e486                	sd	ra,72(sp)
    80005354:	e0a2                	sd	s0,64(sp)
    80005356:	fc26                	sd	s1,56(sp)
    80005358:	f84a                	sd	s2,48(sp)
    8000535a:	f44e                	sd	s3,40(sp)
    8000535c:	f052                	sd	s4,32(sp)
    8000535e:	ec56                	sd	s5,24(sp)
    80005360:	0880                	addi	s0,sp,80
    80005362:	84aa                	mv	s1,a0
    80005364:	892e                	mv	s2,a1
    80005366:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	712080e7          	jalr	1810(ra) # 80001a7a <myproc>
    80005370:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005372:	8526                	mv	a0,s1
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	8c4080e7          	jalr	-1852(ra) # 80000c38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000537c:	2184a703          	lw	a4,536(s1)
    80005380:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005384:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005388:	02f71963          	bne	a4,a5,800053ba <piperead+0x6a>
    8000538c:	2244a783          	lw	a5,548(s1)
    80005390:	cf95                	beqz	a5,800053cc <piperead+0x7c>
    if(killed(pr)){
    80005392:	8552                	mv	a0,s4
    80005394:	ffffd097          	auipc	ra,0xffffd
    80005398:	404080e7          	jalr	1028(ra) # 80002798 <killed>
    8000539c:	e10d                	bnez	a0,800053be <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000539e:	85a6                	mv	a1,s1
    800053a0:	854e                	mv	a0,s3
    800053a2:	ffffd097          	auipc	ra,0xffffd
    800053a6:	142080e7          	jalr	322(ra) # 800024e4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053aa:	2184a703          	lw	a4,536(s1)
    800053ae:	21c4a783          	lw	a5,540(s1)
    800053b2:	fcf70de3          	beq	a4,a5,8000538c <piperead+0x3c>
    800053b6:	e85a                	sd	s6,16(sp)
    800053b8:	a819                	j	800053ce <piperead+0x7e>
    800053ba:	e85a                	sd	s6,16(sp)
    800053bc:	a809                	j	800053ce <piperead+0x7e>
      release(&pi->lock);
    800053be:	8526                	mv	a0,s1
    800053c0:	ffffc097          	auipc	ra,0xffffc
    800053c4:	92c080e7          	jalr	-1748(ra) # 80000cec <release>
      return -1;
    800053c8:	59fd                	li	s3,-1
    800053ca:	a0a5                	j	80005432 <piperead+0xe2>
    800053cc:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053ce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053d0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053d2:	05505463          	blez	s5,8000541a <piperead+0xca>
    if(pi->nread == pi->nwrite)
    800053d6:	2184a783          	lw	a5,536(s1)
    800053da:	21c4a703          	lw	a4,540(s1)
    800053de:	02f70e63          	beq	a4,a5,8000541a <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053e2:	0017871b          	addiw	a4,a5,1
    800053e6:	20e4ac23          	sw	a4,536(s1)
    800053ea:	1ff7f793          	andi	a5,a5,511
    800053ee:	97a6                	add	a5,a5,s1
    800053f0:	0187c783          	lbu	a5,24(a5)
    800053f4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053f8:	4685                	li	a3,1
    800053fa:	fbf40613          	addi	a2,s0,-65
    800053fe:	85ca                	mv	a1,s2
    80005400:	228a3503          	ld	a0,552(s4)
    80005404:	ffffc097          	auipc	ra,0xffffc
    80005408:	2de080e7          	jalr	734(ra) # 800016e2 <copyout>
    8000540c:	01650763          	beq	a0,s6,8000541a <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005410:	2985                	addiw	s3,s3,1
    80005412:	0905                	addi	s2,s2,1
    80005414:	fd3a91e3          	bne	s5,s3,800053d6 <piperead+0x86>
    80005418:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000541a:	21c48513          	addi	a0,s1,540
    8000541e:	ffffd097          	auipc	ra,0xffffd
    80005422:	12a080e7          	jalr	298(ra) # 80002548 <wakeup>
  release(&pi->lock);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	8c4080e7          	jalr	-1852(ra) # 80000cec <release>
    80005430:	6b42                	ld	s6,16(sp)
  return i;
}
    80005432:	854e                	mv	a0,s3
    80005434:	60a6                	ld	ra,72(sp)
    80005436:	6406                	ld	s0,64(sp)
    80005438:	74e2                	ld	s1,56(sp)
    8000543a:	7942                	ld	s2,48(sp)
    8000543c:	79a2                	ld	s3,40(sp)
    8000543e:	7a02                	ld	s4,32(sp)
    80005440:	6ae2                	ld	s5,24(sp)
    80005442:	6161                	addi	sp,sp,80
    80005444:	8082                	ret

0000000080005446 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005446:	1141                	addi	sp,sp,-16
    80005448:	e422                	sd	s0,8(sp)
    8000544a:	0800                	addi	s0,sp,16
    8000544c:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000544e:	8905                	andi	a0,a0,1
    80005450:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005452:	8b89                	andi	a5,a5,2
    80005454:	c399                	beqz	a5,8000545a <flags2perm+0x14>
      perm |= PTE_W;
    80005456:	00456513          	ori	a0,a0,4
    return perm;
}
    8000545a:	6422                	ld	s0,8(sp)
    8000545c:	0141                	addi	sp,sp,16
    8000545e:	8082                	ret

0000000080005460 <exec>:

int
exec(char *path, char **argv)
{
    80005460:	df010113          	addi	sp,sp,-528
    80005464:	20113423          	sd	ra,520(sp)
    80005468:	20813023          	sd	s0,512(sp)
    8000546c:	ffa6                	sd	s1,504(sp)
    8000546e:	fbca                	sd	s2,496(sp)
    80005470:	0c00                	addi	s0,sp,528
    80005472:	892a                	mv	s2,a0
    80005474:	dea43c23          	sd	a0,-520(s0)
    80005478:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	5fe080e7          	jalr	1534(ra) # 80001a7a <myproc>
    80005484:	84aa                	mv	s1,a0

  begin_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	43a080e7          	jalr	1082(ra) # 800048c0 <begin_op>

  if((ip = namei(path)) == 0){
    8000548e:	854a                	mv	a0,s2
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	230080e7          	jalr	560(ra) # 800046c0 <namei>
    80005498:	c135                	beqz	a0,800054fc <exec+0x9c>
    8000549a:	f3d2                	sd	s4,480(sp)
    8000549c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	a54080e7          	jalr	-1452(ra) # 80003ef2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800054a6:	04000713          	li	a4,64
    800054aa:	4681                	li	a3,0
    800054ac:	e5040613          	addi	a2,s0,-432
    800054b0:	4581                	li	a1,0
    800054b2:	8552                	mv	a0,s4
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	cf6080e7          	jalr	-778(ra) # 800041aa <readi>
    800054bc:	04000793          	li	a5,64
    800054c0:	00f51a63          	bne	a0,a5,800054d4 <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800054c4:	e5042703          	lw	a4,-432(s0)
    800054c8:	464c47b7          	lui	a5,0x464c4
    800054cc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054d0:	02f70c63          	beq	a4,a5,80005508 <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054d4:	8552                	mv	a0,s4
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	c82080e7          	jalr	-894(ra) # 80004158 <iunlockput>
    end_op();
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	45c080e7          	jalr	1116(ra) # 8000493a <end_op>
  }
  return -1;
    800054e6:	557d                	li	a0,-1
    800054e8:	7a1e                	ld	s4,480(sp)
}
    800054ea:	20813083          	ld	ra,520(sp)
    800054ee:	20013403          	ld	s0,512(sp)
    800054f2:	74fe                	ld	s1,504(sp)
    800054f4:	795e                	ld	s2,496(sp)
    800054f6:	21010113          	addi	sp,sp,528
    800054fa:	8082                	ret
    end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	43e080e7          	jalr	1086(ra) # 8000493a <end_op>
    return -1;
    80005504:	557d                	li	a0,-1
    80005506:	b7d5                	j	800054ea <exec+0x8a>
    80005508:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffc097          	auipc	ra,0xffffc
    80005510:	632080e7          	jalr	1586(ra) # 80001b3e <proc_pagetable>
    80005514:	8b2a                	mv	s6,a0
    80005516:	30050f63          	beqz	a0,80005834 <exec+0x3d4>
    8000551a:	f7ce                	sd	s3,488(sp)
    8000551c:	efd6                	sd	s5,472(sp)
    8000551e:	e7de                	sd	s7,456(sp)
    80005520:	e3e2                	sd	s8,448(sp)
    80005522:	ff66                	sd	s9,440(sp)
    80005524:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005526:	e7042d03          	lw	s10,-400(s0)
    8000552a:	e8845783          	lhu	a5,-376(s0)
    8000552e:	14078d63          	beqz	a5,80005688 <exec+0x228>
    80005532:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005534:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005536:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005538:	6c85                	lui	s9,0x1
    8000553a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000553e:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005542:	6a85                	lui	s5,0x1
    80005544:	a0b5                	j	800055b0 <exec+0x150>
      panic("loadseg: address should exist");
    80005546:	00003517          	auipc	a0,0x3
    8000554a:	07250513          	addi	a0,a0,114 # 800085b8 <etext+0x5b8>
    8000554e:	ffffb097          	auipc	ra,0xffffb
    80005552:	012080e7          	jalr	18(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    80005556:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005558:	8726                	mv	a4,s1
    8000555a:	012c06bb          	addw	a3,s8,s2
    8000555e:	4581                	li	a1,0
    80005560:	8552                	mv	a0,s4
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	c48080e7          	jalr	-952(ra) # 800041aa <readi>
    8000556a:	2501                	sext.w	a0,a0
    8000556c:	28a49863          	bne	s1,a0,800057fc <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    80005570:	012a893b          	addw	s2,s5,s2
    80005574:	03397563          	bgeu	s2,s3,8000559e <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    80005578:	02091593          	slli	a1,s2,0x20
    8000557c:	9181                	srli	a1,a1,0x20
    8000557e:	95de                	add	a1,a1,s7
    80005580:	855a                	mv	a0,s6
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	b34080e7          	jalr	-1228(ra) # 800010b6 <walkaddr>
    8000558a:	862a                	mv	a2,a0
    if(pa == 0)
    8000558c:	dd4d                	beqz	a0,80005546 <exec+0xe6>
    if(sz - i < PGSIZE)
    8000558e:	412984bb          	subw	s1,s3,s2
    80005592:	0004879b          	sext.w	a5,s1
    80005596:	fcfcf0e3          	bgeu	s9,a5,80005556 <exec+0xf6>
    8000559a:	84d6                	mv	s1,s5
    8000559c:	bf6d                	j	80005556 <exec+0xf6>
    sz = sz1;
    8000559e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055a2:	2d85                	addiw	s11,s11,1
    800055a4:	038d0d1b          	addiw	s10,s10,56
    800055a8:	e8845783          	lhu	a5,-376(s0)
    800055ac:	08fdd663          	bge	s11,a5,80005638 <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055b0:	2d01                	sext.w	s10,s10
    800055b2:	03800713          	li	a4,56
    800055b6:	86ea                	mv	a3,s10
    800055b8:	e1840613          	addi	a2,s0,-488
    800055bc:	4581                	li	a1,0
    800055be:	8552                	mv	a0,s4
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	bea080e7          	jalr	-1046(ra) # 800041aa <readi>
    800055c8:	03800793          	li	a5,56
    800055cc:	20f51063          	bne	a0,a5,800057cc <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    800055d0:	e1842783          	lw	a5,-488(s0)
    800055d4:	4705                	li	a4,1
    800055d6:	fce796e3          	bne	a5,a4,800055a2 <exec+0x142>
    if(ph.memsz < ph.filesz)
    800055da:	e4043483          	ld	s1,-448(s0)
    800055de:	e3843783          	ld	a5,-456(s0)
    800055e2:	1ef4e963          	bltu	s1,a5,800057d4 <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055e6:	e2843783          	ld	a5,-472(s0)
    800055ea:	94be                	add	s1,s1,a5
    800055ec:	1ef4e863          	bltu	s1,a5,800057dc <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    800055f0:	df043703          	ld	a4,-528(s0)
    800055f4:	8ff9                	and	a5,a5,a4
    800055f6:	1e079763          	bnez	a5,800057e4 <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055fa:	e1c42503          	lw	a0,-484(s0)
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	e48080e7          	jalr	-440(ra) # 80005446 <flags2perm>
    80005606:	86aa                	mv	a3,a0
    80005608:	8626                	mv	a2,s1
    8000560a:	85ca                	mv	a1,s2
    8000560c:	855a                	mv	a0,s6
    8000560e:	ffffc097          	auipc	ra,0xffffc
    80005612:	e6c080e7          	jalr	-404(ra) # 8000147a <uvmalloc>
    80005616:	e0a43423          	sd	a0,-504(s0)
    8000561a:	1c050963          	beqz	a0,800057ec <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000561e:	e2843b83          	ld	s7,-472(s0)
    80005622:	e2042c03          	lw	s8,-480(s0)
    80005626:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000562a:	00098463          	beqz	s3,80005632 <exec+0x1d2>
    8000562e:	4901                	li	s2,0
    80005630:	b7a1                	j	80005578 <exec+0x118>
    sz = sz1;
    80005632:	e0843903          	ld	s2,-504(s0)
    80005636:	b7b5                	j	800055a2 <exec+0x142>
    80005638:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    8000563a:	8552                	mv	a0,s4
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	b1c080e7          	jalr	-1252(ra) # 80004158 <iunlockput>
  end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	2f6080e7          	jalr	758(ra) # 8000493a <end_op>
  p = myproc();
    8000564c:	ffffc097          	auipc	ra,0xffffc
    80005650:	42e080e7          	jalr	1070(ra) # 80001a7a <myproc>
    80005654:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005656:	22053c83          	ld	s9,544(a0)
  sz = PGROUNDUP(sz);
    8000565a:	6985                	lui	s3,0x1
    8000565c:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000565e:	99ca                	add	s3,s3,s2
    80005660:	77fd                	lui	a5,0xfffff
    80005662:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005666:	4691                	li	a3,4
    80005668:	6609                	lui	a2,0x2
    8000566a:	964e                	add	a2,a2,s3
    8000566c:	85ce                	mv	a1,s3
    8000566e:	855a                	mv	a0,s6
    80005670:	ffffc097          	auipc	ra,0xffffc
    80005674:	e0a080e7          	jalr	-502(ra) # 8000147a <uvmalloc>
    80005678:	892a                	mv	s2,a0
    8000567a:	e0a43423          	sd	a0,-504(s0)
    8000567e:	e519                	bnez	a0,8000568c <exec+0x22c>
  if(pagetable)
    80005680:	e1343423          	sd	s3,-504(s0)
    80005684:	4a01                	li	s4,0
    80005686:	aaa5                	j	800057fe <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005688:	4901                	li	s2,0
    8000568a:	bf45                	j	8000563a <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000568c:	75f9                	lui	a1,0xffffe
    8000568e:	95aa                	add	a1,a1,a0
    80005690:	855a                	mv	a0,s6
    80005692:	ffffc097          	auipc	ra,0xffffc
    80005696:	01e080e7          	jalr	30(ra) # 800016b0 <uvmclear>
  stackbase = sp - PGSIZE;
    8000569a:	7bfd                	lui	s7,0xfffff
    8000569c:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000569e:	e0043783          	ld	a5,-512(s0)
    800056a2:	6388                	ld	a0,0(a5)
    800056a4:	c52d                	beqz	a0,8000570e <exec+0x2ae>
    800056a6:	e9040993          	addi	s3,s0,-368
    800056aa:	f9040c13          	addi	s8,s0,-112
    800056ae:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	7f8080e7          	jalr	2040(ra) # 80000ea8 <strlen>
    800056b8:	0015079b          	addiw	a5,a0,1
    800056bc:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800056c0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800056c4:	13796863          	bltu	s2,s7,800057f4 <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056c8:	e0043d03          	ld	s10,-512(s0)
    800056cc:	000d3a03          	ld	s4,0(s10)
    800056d0:	8552                	mv	a0,s4
    800056d2:	ffffb097          	auipc	ra,0xffffb
    800056d6:	7d6080e7          	jalr	2006(ra) # 80000ea8 <strlen>
    800056da:	0015069b          	addiw	a3,a0,1
    800056de:	8652                	mv	a2,s4
    800056e0:	85ca                	mv	a1,s2
    800056e2:	855a                	mv	a0,s6
    800056e4:	ffffc097          	auipc	ra,0xffffc
    800056e8:	ffe080e7          	jalr	-2(ra) # 800016e2 <copyout>
    800056ec:	10054663          	bltz	a0,800057f8 <exec+0x398>
    ustack[argc] = sp;
    800056f0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056f4:	0485                	addi	s1,s1,1
    800056f6:	008d0793          	addi	a5,s10,8
    800056fa:	e0f43023          	sd	a5,-512(s0)
    800056fe:	008d3503          	ld	a0,8(s10)
    80005702:	c909                	beqz	a0,80005714 <exec+0x2b4>
    if(argc >= MAXARG)
    80005704:	09a1                	addi	s3,s3,8
    80005706:	fb8995e3          	bne	s3,s8,800056b0 <exec+0x250>
  ip = 0;
    8000570a:	4a01                	li	s4,0
    8000570c:	a8cd                	j	800057fe <exec+0x39e>
  sp = sz;
    8000570e:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005712:	4481                	li	s1,0
  ustack[argc] = 0;
    80005714:	00349793          	slli	a5,s1,0x3
    80005718:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd2510>
    8000571c:	97a2                	add	a5,a5,s0
    8000571e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005722:	00148693          	addi	a3,s1,1
    80005726:	068e                	slli	a3,a3,0x3
    80005728:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000572c:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005730:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005734:	f57966e3          	bltu	s2,s7,80005680 <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005738:	e9040613          	addi	a2,s0,-368
    8000573c:	85ca                	mv	a1,s2
    8000573e:	855a                	mv	a0,s6
    80005740:	ffffc097          	auipc	ra,0xffffc
    80005744:	fa2080e7          	jalr	-94(ra) # 800016e2 <copyout>
    80005748:	0e054863          	bltz	a0,80005838 <exec+0x3d8>
  p->trapframe->a1 = sp;
    8000574c:	230ab783          	ld	a5,560(s5) # 1230 <_entry-0x7fffedd0>
    80005750:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005754:	df843783          	ld	a5,-520(s0)
    80005758:	0007c703          	lbu	a4,0(a5)
    8000575c:	cf11                	beqz	a4,80005778 <exec+0x318>
    8000575e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005760:	02f00693          	li	a3,47
    80005764:	a039                	j	80005772 <exec+0x312>
      last = s+1;
    80005766:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000576a:	0785                	addi	a5,a5,1
    8000576c:	fff7c703          	lbu	a4,-1(a5)
    80005770:	c701                	beqz	a4,80005778 <exec+0x318>
    if(*s == '/')
    80005772:	fed71ce3          	bne	a4,a3,8000576a <exec+0x30a>
    80005776:	bfc5                	j	80005766 <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    80005778:	4641                	li	a2,16
    8000577a:	df843583          	ld	a1,-520(s0)
    8000577e:	330a8513          	addi	a0,s5,816
    80005782:	ffffb097          	auipc	ra,0xffffb
    80005786:	6f4080e7          	jalr	1780(ra) # 80000e76 <safestrcpy>
  oldpagetable = p->pagetable;
    8000578a:	228ab503          	ld	a0,552(s5)
  p->pagetable = pagetable;
    8000578e:	236ab423          	sd	s6,552(s5)
  p->sz = sz;
    80005792:	e0843783          	ld	a5,-504(s0)
    80005796:	22fab023          	sd	a5,544(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000579a:	230ab783          	ld	a5,560(s5)
    8000579e:	e6843703          	ld	a4,-408(s0)
    800057a2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800057a4:	230ab783          	ld	a5,560(s5)
    800057a8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800057ac:	85e6                	mv	a1,s9
    800057ae:	ffffc097          	auipc	ra,0xffffc
    800057b2:	42c080e7          	jalr	1068(ra) # 80001bda <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800057b6:	0004851b          	sext.w	a0,s1
    800057ba:	79be                	ld	s3,488(sp)
    800057bc:	7a1e                	ld	s4,480(sp)
    800057be:	6afe                	ld	s5,472(sp)
    800057c0:	6b5e                	ld	s6,464(sp)
    800057c2:	6bbe                	ld	s7,456(sp)
    800057c4:	6c1e                	ld	s8,448(sp)
    800057c6:	7cfa                	ld	s9,440(sp)
    800057c8:	7d5a                	ld	s10,432(sp)
    800057ca:	b305                	j	800054ea <exec+0x8a>
    800057cc:	e1243423          	sd	s2,-504(s0)
    800057d0:	7dba                	ld	s11,424(sp)
    800057d2:	a035                	j	800057fe <exec+0x39e>
    800057d4:	e1243423          	sd	s2,-504(s0)
    800057d8:	7dba                	ld	s11,424(sp)
    800057da:	a015                	j	800057fe <exec+0x39e>
    800057dc:	e1243423          	sd	s2,-504(s0)
    800057e0:	7dba                	ld	s11,424(sp)
    800057e2:	a831                	j	800057fe <exec+0x39e>
    800057e4:	e1243423          	sd	s2,-504(s0)
    800057e8:	7dba                	ld	s11,424(sp)
    800057ea:	a811                	j	800057fe <exec+0x39e>
    800057ec:	e1243423          	sd	s2,-504(s0)
    800057f0:	7dba                	ld	s11,424(sp)
    800057f2:	a031                	j	800057fe <exec+0x39e>
  ip = 0;
    800057f4:	4a01                	li	s4,0
    800057f6:	a021                	j	800057fe <exec+0x39e>
    800057f8:	4a01                	li	s4,0
  if(pagetable)
    800057fa:	a011                	j	800057fe <exec+0x39e>
    800057fc:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    800057fe:	e0843583          	ld	a1,-504(s0)
    80005802:	855a                	mv	a0,s6
    80005804:	ffffc097          	auipc	ra,0xffffc
    80005808:	3d6080e7          	jalr	982(ra) # 80001bda <proc_freepagetable>
  return -1;
    8000580c:	557d                	li	a0,-1
  if(ip){
    8000580e:	000a1b63          	bnez	s4,80005824 <exec+0x3c4>
    80005812:	79be                	ld	s3,488(sp)
    80005814:	7a1e                	ld	s4,480(sp)
    80005816:	6afe                	ld	s5,472(sp)
    80005818:	6b5e                	ld	s6,464(sp)
    8000581a:	6bbe                	ld	s7,456(sp)
    8000581c:	6c1e                	ld	s8,448(sp)
    8000581e:	7cfa                	ld	s9,440(sp)
    80005820:	7d5a                	ld	s10,432(sp)
    80005822:	b1e1                	j	800054ea <exec+0x8a>
    80005824:	79be                	ld	s3,488(sp)
    80005826:	6afe                	ld	s5,472(sp)
    80005828:	6b5e                	ld	s6,464(sp)
    8000582a:	6bbe                	ld	s7,456(sp)
    8000582c:	6c1e                	ld	s8,448(sp)
    8000582e:	7cfa                	ld	s9,440(sp)
    80005830:	7d5a                	ld	s10,432(sp)
    80005832:	b14d                	j	800054d4 <exec+0x74>
    80005834:	6b5e                	ld	s6,464(sp)
    80005836:	b979                	j	800054d4 <exec+0x74>
  sz = sz1;
    80005838:	e0843983          	ld	s3,-504(s0)
    8000583c:	b591                	j	80005680 <exec+0x220>

000000008000583e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000583e:	7179                	addi	sp,sp,-48
    80005840:	f406                	sd	ra,40(sp)
    80005842:	f022                	sd	s0,32(sp)
    80005844:	ec26                	sd	s1,24(sp)
    80005846:	e84a                	sd	s2,16(sp)
    80005848:	1800                	addi	s0,sp,48
    8000584a:	892e                	mv	s2,a1
    8000584c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000584e:	fdc40593          	addi	a1,s0,-36
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	960080e7          	jalr	-1696(ra) # 800031b2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000585a:	fdc42703          	lw	a4,-36(s0)
    8000585e:	47bd                	li	a5,15
    80005860:	02e7eb63          	bltu	a5,a4,80005896 <argfd+0x58>
    80005864:	ffffc097          	auipc	ra,0xffffc
    80005868:	216080e7          	jalr	534(ra) # 80001a7a <myproc>
    8000586c:	fdc42703          	lw	a4,-36(s0)
    80005870:	05470793          	addi	a5,a4,84
    80005874:	078e                	slli	a5,a5,0x3
    80005876:	953e                	add	a0,a0,a5
    80005878:	651c                	ld	a5,8(a0)
    8000587a:	c385                	beqz	a5,8000589a <argfd+0x5c>
    return -1;
  if(pfd)
    8000587c:	00090463          	beqz	s2,80005884 <argfd+0x46>
    *pfd = fd;
    80005880:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005884:	4501                	li	a0,0
  if(pf)
    80005886:	c091                	beqz	s1,8000588a <argfd+0x4c>
    *pf = f;
    80005888:	e09c                	sd	a5,0(s1)
}
    8000588a:	70a2                	ld	ra,40(sp)
    8000588c:	7402                	ld	s0,32(sp)
    8000588e:	64e2                	ld	s1,24(sp)
    80005890:	6942                	ld	s2,16(sp)
    80005892:	6145                	addi	sp,sp,48
    80005894:	8082                	ret
    return -1;
    80005896:	557d                	li	a0,-1
    80005898:	bfcd                	j	8000588a <argfd+0x4c>
    8000589a:	557d                	li	a0,-1
    8000589c:	b7fd                	j	8000588a <argfd+0x4c>

000000008000589e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000589e:	1101                	addi	sp,sp,-32
    800058a0:	ec06                	sd	ra,24(sp)
    800058a2:	e822                	sd	s0,16(sp)
    800058a4:	e426                	sd	s1,8(sp)
    800058a6:	1000                	addi	s0,sp,32
    800058a8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058aa:	ffffc097          	auipc	ra,0xffffc
    800058ae:	1d0080e7          	jalr	464(ra) # 80001a7a <myproc>
    800058b2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058b4:	2a850793          	addi	a5,a0,680
    800058b8:	4501                	li	a0,0
    800058ba:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058bc:	6398                	ld	a4,0(a5)
    800058be:	cb19                	beqz	a4,800058d4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058c0:	2505                	addiw	a0,a0,1
    800058c2:	07a1                	addi	a5,a5,8
    800058c4:	fed51ce3          	bne	a0,a3,800058bc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058c8:	557d                	li	a0,-1
}
    800058ca:	60e2                	ld	ra,24(sp)
    800058cc:	6442                	ld	s0,16(sp)
    800058ce:	64a2                	ld	s1,8(sp)
    800058d0:	6105                	addi	sp,sp,32
    800058d2:	8082                	ret
      p->ofile[fd] = f;
    800058d4:	05450793          	addi	a5,a0,84
    800058d8:	078e                	slli	a5,a5,0x3
    800058da:	963e                	add	a2,a2,a5
    800058dc:	e604                	sd	s1,8(a2)
      return fd;
    800058de:	b7f5                	j	800058ca <fdalloc+0x2c>

00000000800058e0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058e0:	715d                	addi	sp,sp,-80
    800058e2:	e486                	sd	ra,72(sp)
    800058e4:	e0a2                	sd	s0,64(sp)
    800058e6:	fc26                	sd	s1,56(sp)
    800058e8:	f84a                	sd	s2,48(sp)
    800058ea:	f44e                	sd	s3,40(sp)
    800058ec:	ec56                	sd	s5,24(sp)
    800058ee:	e85a                	sd	s6,16(sp)
    800058f0:	0880                	addi	s0,sp,80
    800058f2:	8b2e                	mv	s6,a1
    800058f4:	89b2                	mv	s3,a2
    800058f6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800058f8:	fb040593          	addi	a1,s0,-80
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	de2080e7          	jalr	-542(ra) # 800046de <nameiparent>
    80005904:	84aa                	mv	s1,a0
    80005906:	14050e63          	beqz	a0,80005a62 <create+0x182>
    return 0;

  ilock(dp);
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	5e8080e7          	jalr	1512(ra) # 80003ef2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005912:	4601                	li	a2,0
    80005914:	fb040593          	addi	a1,s0,-80
    80005918:	8526                	mv	a0,s1
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	ae4080e7          	jalr	-1308(ra) # 800043fe <dirlookup>
    80005922:	8aaa                	mv	s5,a0
    80005924:	c539                	beqz	a0,80005972 <create+0x92>
    iunlockput(dp);
    80005926:	8526                	mv	a0,s1
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	830080e7          	jalr	-2000(ra) # 80004158 <iunlockput>
    ilock(ip);
    80005930:	8556                	mv	a0,s5
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	5c0080e7          	jalr	1472(ra) # 80003ef2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000593a:	4789                	li	a5,2
    8000593c:	02fb1463          	bne	s6,a5,80005964 <create+0x84>
    80005940:	044ad783          	lhu	a5,68(s5)
    80005944:	37f9                	addiw	a5,a5,-2
    80005946:	17c2                	slli	a5,a5,0x30
    80005948:	93c1                	srli	a5,a5,0x30
    8000594a:	4705                	li	a4,1
    8000594c:	00f76c63          	bltu	a4,a5,80005964 <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005950:	8556                	mv	a0,s5
    80005952:	60a6                	ld	ra,72(sp)
    80005954:	6406                	ld	s0,64(sp)
    80005956:	74e2                	ld	s1,56(sp)
    80005958:	7942                	ld	s2,48(sp)
    8000595a:	79a2                	ld	s3,40(sp)
    8000595c:	6ae2                	ld	s5,24(sp)
    8000595e:	6b42                	ld	s6,16(sp)
    80005960:	6161                	addi	sp,sp,80
    80005962:	8082                	ret
    iunlockput(ip);
    80005964:	8556                	mv	a0,s5
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	7f2080e7          	jalr	2034(ra) # 80004158 <iunlockput>
    return 0;
    8000596e:	4a81                	li	s5,0
    80005970:	b7c5                	j	80005950 <create+0x70>
    80005972:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005974:	85da                	mv	a1,s6
    80005976:	4088                	lw	a0,0(s1)
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	3d6080e7          	jalr	982(ra) # 80003d4e <ialloc>
    80005980:	8a2a                	mv	s4,a0
    80005982:	c531                	beqz	a0,800059ce <create+0xee>
  ilock(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	56e080e7          	jalr	1390(ra) # 80003ef2 <ilock>
  ip->major = major;
    8000598c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005990:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005994:	4905                	li	s2,1
    80005996:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000599a:	8552                	mv	a0,s4
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	48a080e7          	jalr	1162(ra) # 80003e26 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059a4:	032b0d63          	beq	s6,s2,800059de <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800059a8:	004a2603          	lw	a2,4(s4)
    800059ac:	fb040593          	addi	a1,s0,-80
    800059b0:	8526                	mv	a0,s1
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	c5c080e7          	jalr	-932(ra) # 8000460e <dirlink>
    800059ba:	08054163          	bltz	a0,80005a3c <create+0x15c>
  iunlockput(dp);
    800059be:	8526                	mv	a0,s1
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	798080e7          	jalr	1944(ra) # 80004158 <iunlockput>
  return ip;
    800059c8:	8ad2                	mv	s5,s4
    800059ca:	7a02                	ld	s4,32(sp)
    800059cc:	b751                	j	80005950 <create+0x70>
    iunlockput(dp);
    800059ce:	8526                	mv	a0,s1
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	788080e7          	jalr	1928(ra) # 80004158 <iunlockput>
    return 0;
    800059d8:	8ad2                	mv	s5,s4
    800059da:	7a02                	ld	s4,32(sp)
    800059dc:	bf95                	j	80005950 <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800059de:	004a2603          	lw	a2,4(s4)
    800059e2:	00003597          	auipc	a1,0x3
    800059e6:	bf658593          	addi	a1,a1,-1034 # 800085d8 <etext+0x5d8>
    800059ea:	8552                	mv	a0,s4
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	c22080e7          	jalr	-990(ra) # 8000460e <dirlink>
    800059f4:	04054463          	bltz	a0,80005a3c <create+0x15c>
    800059f8:	40d0                	lw	a2,4(s1)
    800059fa:	00003597          	auipc	a1,0x3
    800059fe:	be658593          	addi	a1,a1,-1050 # 800085e0 <etext+0x5e0>
    80005a02:	8552                	mv	a0,s4
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	c0a080e7          	jalr	-1014(ra) # 8000460e <dirlink>
    80005a0c:	02054863          	bltz	a0,80005a3c <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a10:	004a2603          	lw	a2,4(s4)
    80005a14:	fb040593          	addi	a1,s0,-80
    80005a18:	8526                	mv	a0,s1
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	bf4080e7          	jalr	-1036(ra) # 8000460e <dirlink>
    80005a22:	00054d63          	bltz	a0,80005a3c <create+0x15c>
    dp->nlink++;  // for ".."
    80005a26:	04a4d783          	lhu	a5,74(s1)
    80005a2a:	2785                	addiw	a5,a5,1
    80005a2c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	3f4080e7          	jalr	1012(ra) # 80003e26 <iupdate>
    80005a3a:	b751                	j	800059be <create+0xde>
  ip->nlink = 0;
    80005a3c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005a40:	8552                	mv	a0,s4
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	3e4080e7          	jalr	996(ra) # 80003e26 <iupdate>
  iunlockput(ip);
    80005a4a:	8552                	mv	a0,s4
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	70c080e7          	jalr	1804(ra) # 80004158 <iunlockput>
  iunlockput(dp);
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	702080e7          	jalr	1794(ra) # 80004158 <iunlockput>
  return 0;
    80005a5e:	7a02                	ld	s4,32(sp)
    80005a60:	bdc5                	j	80005950 <create+0x70>
    return 0;
    80005a62:	8aaa                	mv	s5,a0
    80005a64:	b5f5                	j	80005950 <create+0x70>

0000000080005a66 <sys_dup>:
{
    80005a66:	7179                	addi	sp,sp,-48
    80005a68:	f406                	sd	ra,40(sp)
    80005a6a:	f022                	sd	s0,32(sp)
    80005a6c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a6e:	fd840613          	addi	a2,s0,-40
    80005a72:	4581                	li	a1,0
    80005a74:	4501                	li	a0,0
    80005a76:	00000097          	auipc	ra,0x0
    80005a7a:	dc8080e7          	jalr	-568(ra) # 8000583e <argfd>
    return -1;
    80005a7e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a80:	02054763          	bltz	a0,80005aae <sys_dup+0x48>
    80005a84:	ec26                	sd	s1,24(sp)
    80005a86:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005a88:	fd843903          	ld	s2,-40(s0)
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	00000097          	auipc	ra,0x0
    80005a92:	e10080e7          	jalr	-496(ra) # 8000589e <fdalloc>
    80005a96:	84aa                	mv	s1,a0
    return -1;
    80005a98:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a9a:	00054f63          	bltz	a0,80005ab8 <sys_dup+0x52>
  filedup(f);
    80005a9e:	854a                	mv	a0,s2
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	298080e7          	jalr	664(ra) # 80004d38 <filedup>
  return fd;
    80005aa8:	87a6                	mv	a5,s1
    80005aaa:	64e2                	ld	s1,24(sp)
    80005aac:	6942                	ld	s2,16(sp)
}
    80005aae:	853e                	mv	a0,a5
    80005ab0:	70a2                	ld	ra,40(sp)
    80005ab2:	7402                	ld	s0,32(sp)
    80005ab4:	6145                	addi	sp,sp,48
    80005ab6:	8082                	ret
    80005ab8:	64e2                	ld	s1,24(sp)
    80005aba:	6942                	ld	s2,16(sp)
    80005abc:	bfcd                	j	80005aae <sys_dup+0x48>

0000000080005abe <sys_read>:
{
    80005abe:	7179                	addi	sp,sp,-48
    80005ac0:	f406                	sd	ra,40(sp)
    80005ac2:	f022                	sd	s0,32(sp)
    80005ac4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ac6:	fd840593          	addi	a1,s0,-40
    80005aca:	4505                	li	a0,1
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	706080e7          	jalr	1798(ra) # 800031d2 <argaddr>
  argint(2, &n);
    80005ad4:	fe440593          	addi	a1,s0,-28
    80005ad8:	4509                	li	a0,2
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	6d8080e7          	jalr	1752(ra) # 800031b2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ae2:	fe840613          	addi	a2,s0,-24
    80005ae6:	4581                	li	a1,0
    80005ae8:	4501                	li	a0,0
    80005aea:	00000097          	auipc	ra,0x0
    80005aee:	d54080e7          	jalr	-684(ra) # 8000583e <argfd>
    80005af2:	87aa                	mv	a5,a0
    return -1;
    80005af4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005af6:	0007cc63          	bltz	a5,80005b0e <sys_read+0x50>
  return fileread(f, p, n);
    80005afa:	fe442603          	lw	a2,-28(s0)
    80005afe:	fd843583          	ld	a1,-40(s0)
    80005b02:	fe843503          	ld	a0,-24(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	3d8080e7          	jalr	984(ra) # 80004ede <fileread>
}
    80005b0e:	70a2                	ld	ra,40(sp)
    80005b10:	7402                	ld	s0,32(sp)
    80005b12:	6145                	addi	sp,sp,48
    80005b14:	8082                	ret

0000000080005b16 <sys_write>:
{
    80005b16:	7179                	addi	sp,sp,-48
    80005b18:	f406                	sd	ra,40(sp)
    80005b1a:	f022                	sd	s0,32(sp)
    80005b1c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005b1e:	fd840593          	addi	a1,s0,-40
    80005b22:	4505                	li	a0,1
    80005b24:	ffffd097          	auipc	ra,0xffffd
    80005b28:	6ae080e7          	jalr	1710(ra) # 800031d2 <argaddr>
  argint(2, &n);
    80005b2c:	fe440593          	addi	a1,s0,-28
    80005b30:	4509                	li	a0,2
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	680080e7          	jalr	1664(ra) # 800031b2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005b3a:	fe840613          	addi	a2,s0,-24
    80005b3e:	4581                	li	a1,0
    80005b40:	4501                	li	a0,0
    80005b42:	00000097          	auipc	ra,0x0
    80005b46:	cfc080e7          	jalr	-772(ra) # 8000583e <argfd>
    80005b4a:	87aa                	mv	a5,a0
    return -1;
    80005b4c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b4e:	0007cc63          	bltz	a5,80005b66 <sys_write+0x50>
  return filewrite(f, p, n);
    80005b52:	fe442603          	lw	a2,-28(s0)
    80005b56:	fd843583          	ld	a1,-40(s0)
    80005b5a:	fe843503          	ld	a0,-24(s0)
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	452080e7          	jalr	1106(ra) # 80004fb0 <filewrite>
}
    80005b66:	70a2                	ld	ra,40(sp)
    80005b68:	7402                	ld	s0,32(sp)
    80005b6a:	6145                	addi	sp,sp,48
    80005b6c:	8082                	ret

0000000080005b6e <sys_close>:
{
    80005b6e:	1101                	addi	sp,sp,-32
    80005b70:	ec06                	sd	ra,24(sp)
    80005b72:	e822                	sd	s0,16(sp)
    80005b74:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b76:	fe040613          	addi	a2,s0,-32
    80005b7a:	fec40593          	addi	a1,s0,-20
    80005b7e:	4501                	li	a0,0
    80005b80:	00000097          	auipc	ra,0x0
    80005b84:	cbe080e7          	jalr	-834(ra) # 8000583e <argfd>
    return -1;
    80005b88:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b8a:	02054563          	bltz	a0,80005bb4 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005b8e:	ffffc097          	auipc	ra,0xffffc
    80005b92:	eec080e7          	jalr	-276(ra) # 80001a7a <myproc>
    80005b96:	fec42783          	lw	a5,-20(s0)
    80005b9a:	05478793          	addi	a5,a5,84
    80005b9e:	078e                	slli	a5,a5,0x3
    80005ba0:	953e                	add	a0,a0,a5
    80005ba2:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005ba6:	fe043503          	ld	a0,-32(s0)
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	1e0080e7          	jalr	480(ra) # 80004d8a <fileclose>
  return 0;
    80005bb2:	4781                	li	a5,0
}
    80005bb4:	853e                	mv	a0,a5
    80005bb6:	60e2                	ld	ra,24(sp)
    80005bb8:	6442                	ld	s0,16(sp)
    80005bba:	6105                	addi	sp,sp,32
    80005bbc:	8082                	ret

0000000080005bbe <sys_fstat>:
{
    80005bbe:	1101                	addi	sp,sp,-32
    80005bc0:	ec06                	sd	ra,24(sp)
    80005bc2:	e822                	sd	s0,16(sp)
    80005bc4:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005bc6:	fe040593          	addi	a1,s0,-32
    80005bca:	4505                	li	a0,1
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	606080e7          	jalr	1542(ra) # 800031d2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005bd4:	fe840613          	addi	a2,s0,-24
    80005bd8:	4581                	li	a1,0
    80005bda:	4501                	li	a0,0
    80005bdc:	00000097          	auipc	ra,0x0
    80005be0:	c62080e7          	jalr	-926(ra) # 8000583e <argfd>
    80005be4:	87aa                	mv	a5,a0
    return -1;
    80005be6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005be8:	0007ca63          	bltz	a5,80005bfc <sys_fstat+0x3e>
  return filestat(f, st);
    80005bec:	fe043583          	ld	a1,-32(s0)
    80005bf0:	fe843503          	ld	a0,-24(s0)
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	278080e7          	jalr	632(ra) # 80004e6c <filestat>
}
    80005bfc:	60e2                	ld	ra,24(sp)
    80005bfe:	6442                	ld	s0,16(sp)
    80005c00:	6105                	addi	sp,sp,32
    80005c02:	8082                	ret

0000000080005c04 <sys_link>:
{
    80005c04:	7169                	addi	sp,sp,-304
    80005c06:	f606                	sd	ra,296(sp)
    80005c08:	f222                	sd	s0,288(sp)
    80005c0a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c0c:	08000613          	li	a2,128
    80005c10:	ed040593          	addi	a1,s0,-304
    80005c14:	4501                	li	a0,0
    80005c16:	ffffd097          	auipc	ra,0xffffd
    80005c1a:	5dc080e7          	jalr	1500(ra) # 800031f2 <argstr>
    return -1;
    80005c1e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c20:	12054663          	bltz	a0,80005d4c <sys_link+0x148>
    80005c24:	08000613          	li	a2,128
    80005c28:	f5040593          	addi	a1,s0,-176
    80005c2c:	4505                	li	a0,1
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	5c4080e7          	jalr	1476(ra) # 800031f2 <argstr>
    return -1;
    80005c36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c38:	10054a63          	bltz	a0,80005d4c <sys_link+0x148>
    80005c3c:	ee26                	sd	s1,280(sp)
  begin_op();
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	c82080e7          	jalr	-894(ra) # 800048c0 <begin_op>
  if((ip = namei(old)) == 0){
    80005c46:	ed040513          	addi	a0,s0,-304
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	a76080e7          	jalr	-1418(ra) # 800046c0 <namei>
    80005c52:	84aa                	mv	s1,a0
    80005c54:	c949                	beqz	a0,80005ce6 <sys_link+0xe2>
  ilock(ip);
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	29c080e7          	jalr	668(ra) # 80003ef2 <ilock>
  if(ip->type == T_DIR){
    80005c5e:	04449703          	lh	a4,68(s1)
    80005c62:	4785                	li	a5,1
    80005c64:	08f70863          	beq	a4,a5,80005cf4 <sys_link+0xf0>
    80005c68:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005c6a:	04a4d783          	lhu	a5,74(s1)
    80005c6e:	2785                	addiw	a5,a5,1
    80005c70:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c74:	8526                	mv	a0,s1
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	1b0080e7          	jalr	432(ra) # 80003e26 <iupdate>
  iunlock(ip);
    80005c7e:	8526                	mv	a0,s1
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	338080e7          	jalr	824(ra) # 80003fb8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c88:	fd040593          	addi	a1,s0,-48
    80005c8c:	f5040513          	addi	a0,s0,-176
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	a4e080e7          	jalr	-1458(ra) # 800046de <nameiparent>
    80005c98:	892a                	mv	s2,a0
    80005c9a:	cd35                	beqz	a0,80005d16 <sys_link+0x112>
  ilock(dp);
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	256080e7          	jalr	598(ra) # 80003ef2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ca4:	00092703          	lw	a4,0(s2)
    80005ca8:	409c                	lw	a5,0(s1)
    80005caa:	06f71163          	bne	a4,a5,80005d0c <sys_link+0x108>
    80005cae:	40d0                	lw	a2,4(s1)
    80005cb0:	fd040593          	addi	a1,s0,-48
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	958080e7          	jalr	-1704(ra) # 8000460e <dirlink>
    80005cbe:	04054763          	bltz	a0,80005d0c <sys_link+0x108>
  iunlockput(dp);
    80005cc2:	854a                	mv	a0,s2
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	494080e7          	jalr	1172(ra) # 80004158 <iunlockput>
  iput(ip);
    80005ccc:	8526                	mv	a0,s1
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	3e2080e7          	jalr	994(ra) # 800040b0 <iput>
  end_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	c64080e7          	jalr	-924(ra) # 8000493a <end_op>
  return 0;
    80005cde:	4781                	li	a5,0
    80005ce0:	64f2                	ld	s1,280(sp)
    80005ce2:	6952                	ld	s2,272(sp)
    80005ce4:	a0a5                	j	80005d4c <sys_link+0x148>
    end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	c54080e7          	jalr	-940(ra) # 8000493a <end_op>
    return -1;
    80005cee:	57fd                	li	a5,-1
    80005cf0:	64f2                	ld	s1,280(sp)
    80005cf2:	a8a9                	j	80005d4c <sys_link+0x148>
    iunlockput(ip);
    80005cf4:	8526                	mv	a0,s1
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	462080e7          	jalr	1122(ra) # 80004158 <iunlockput>
    end_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	c3c080e7          	jalr	-964(ra) # 8000493a <end_op>
    return -1;
    80005d06:	57fd                	li	a5,-1
    80005d08:	64f2                	ld	s1,280(sp)
    80005d0a:	a089                	j	80005d4c <sys_link+0x148>
    iunlockput(dp);
    80005d0c:	854a                	mv	a0,s2
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	44a080e7          	jalr	1098(ra) # 80004158 <iunlockput>
  ilock(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	1da080e7          	jalr	474(ra) # 80003ef2 <ilock>
  ip->nlink--;
    80005d20:	04a4d783          	lhu	a5,74(s1)
    80005d24:	37fd                	addiw	a5,a5,-1
    80005d26:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d2a:	8526                	mv	a0,s1
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	0fa080e7          	jalr	250(ra) # 80003e26 <iupdate>
  iunlockput(ip);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	422080e7          	jalr	1058(ra) # 80004158 <iunlockput>
  end_op();
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	bfc080e7          	jalr	-1028(ra) # 8000493a <end_op>
  return -1;
    80005d46:	57fd                	li	a5,-1
    80005d48:	64f2                	ld	s1,280(sp)
    80005d4a:	6952                	ld	s2,272(sp)
}
    80005d4c:	853e                	mv	a0,a5
    80005d4e:	70b2                	ld	ra,296(sp)
    80005d50:	7412                	ld	s0,288(sp)
    80005d52:	6155                	addi	sp,sp,304
    80005d54:	8082                	ret

0000000080005d56 <sys_unlink>:
{
    80005d56:	7151                	addi	sp,sp,-240
    80005d58:	f586                	sd	ra,232(sp)
    80005d5a:	f1a2                	sd	s0,224(sp)
    80005d5c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d5e:	08000613          	li	a2,128
    80005d62:	f3040593          	addi	a1,s0,-208
    80005d66:	4501                	li	a0,0
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	48a080e7          	jalr	1162(ra) # 800031f2 <argstr>
    80005d70:	1a054a63          	bltz	a0,80005f24 <sys_unlink+0x1ce>
    80005d74:	eda6                	sd	s1,216(sp)
  begin_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	b4a080e7          	jalr	-1206(ra) # 800048c0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d7e:	fb040593          	addi	a1,s0,-80
    80005d82:	f3040513          	addi	a0,s0,-208
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	958080e7          	jalr	-1704(ra) # 800046de <nameiparent>
    80005d8e:	84aa                	mv	s1,a0
    80005d90:	cd71                	beqz	a0,80005e6c <sys_unlink+0x116>
  ilock(dp);
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	160080e7          	jalr	352(ra) # 80003ef2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d9a:	00003597          	auipc	a1,0x3
    80005d9e:	83e58593          	addi	a1,a1,-1986 # 800085d8 <etext+0x5d8>
    80005da2:	fb040513          	addi	a0,s0,-80
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	63e080e7          	jalr	1598(ra) # 800043e4 <namecmp>
    80005dae:	14050c63          	beqz	a0,80005f06 <sys_unlink+0x1b0>
    80005db2:	00003597          	auipc	a1,0x3
    80005db6:	82e58593          	addi	a1,a1,-2002 # 800085e0 <etext+0x5e0>
    80005dba:	fb040513          	addi	a0,s0,-80
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	626080e7          	jalr	1574(ra) # 800043e4 <namecmp>
    80005dc6:	14050063          	beqz	a0,80005f06 <sys_unlink+0x1b0>
    80005dca:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dcc:	f2c40613          	addi	a2,s0,-212
    80005dd0:	fb040593          	addi	a1,s0,-80
    80005dd4:	8526                	mv	a0,s1
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	628080e7          	jalr	1576(ra) # 800043fe <dirlookup>
    80005dde:	892a                	mv	s2,a0
    80005de0:	12050263          	beqz	a0,80005f04 <sys_unlink+0x1ae>
  ilock(ip);
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	10e080e7          	jalr	270(ra) # 80003ef2 <ilock>
  if(ip->nlink < 1)
    80005dec:	04a91783          	lh	a5,74(s2)
    80005df0:	08f05563          	blez	a5,80005e7a <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005df4:	04491703          	lh	a4,68(s2)
    80005df8:	4785                	li	a5,1
    80005dfa:	08f70963          	beq	a4,a5,80005e8c <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80005dfe:	4641                	li	a2,16
    80005e00:	4581                	li	a1,0
    80005e02:	fc040513          	addi	a0,s0,-64
    80005e06:	ffffb097          	auipc	ra,0xffffb
    80005e0a:	f2e080e7          	jalr	-210(ra) # 80000d34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e0e:	4741                	li	a4,16
    80005e10:	f2c42683          	lw	a3,-212(s0)
    80005e14:	fc040613          	addi	a2,s0,-64
    80005e18:	4581                	li	a1,0
    80005e1a:	8526                	mv	a0,s1
    80005e1c:	ffffe097          	auipc	ra,0xffffe
    80005e20:	49e080e7          	jalr	1182(ra) # 800042ba <writei>
    80005e24:	47c1                	li	a5,16
    80005e26:	0af51b63          	bne	a0,a5,80005edc <sys_unlink+0x186>
  if(ip->type == T_DIR){
    80005e2a:	04491703          	lh	a4,68(s2)
    80005e2e:	4785                	li	a5,1
    80005e30:	0af70f63          	beq	a4,a5,80005eee <sys_unlink+0x198>
  iunlockput(dp);
    80005e34:	8526                	mv	a0,s1
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	322080e7          	jalr	802(ra) # 80004158 <iunlockput>
  ip->nlink--;
    80005e3e:	04a95783          	lhu	a5,74(s2)
    80005e42:	37fd                	addiw	a5,a5,-1
    80005e44:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e48:	854a                	mv	a0,s2
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	fdc080e7          	jalr	-36(ra) # 80003e26 <iupdate>
  iunlockput(ip);
    80005e52:	854a                	mv	a0,s2
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	304080e7          	jalr	772(ra) # 80004158 <iunlockput>
  end_op();
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	ade080e7          	jalr	-1314(ra) # 8000493a <end_op>
  return 0;
    80005e64:	4501                	li	a0,0
    80005e66:	64ee                	ld	s1,216(sp)
    80005e68:	694e                	ld	s2,208(sp)
    80005e6a:	a84d                	j	80005f1c <sys_unlink+0x1c6>
    end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	ace080e7          	jalr	-1330(ra) # 8000493a <end_op>
    return -1;
    80005e74:	557d                	li	a0,-1
    80005e76:	64ee                	ld	s1,216(sp)
    80005e78:	a055                	j	80005f1c <sys_unlink+0x1c6>
    80005e7a:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005e7c:	00002517          	auipc	a0,0x2
    80005e80:	76c50513          	addi	a0,a0,1900 # 800085e8 <etext+0x5e8>
    80005e84:	ffffa097          	auipc	ra,0xffffa
    80005e88:	6dc080e7          	jalr	1756(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e8c:	04c92703          	lw	a4,76(s2)
    80005e90:	02000793          	li	a5,32
    80005e94:	f6e7f5e3          	bgeu	a5,a4,80005dfe <sys_unlink+0xa8>
    80005e98:	e5ce                	sd	s3,200(sp)
    80005e9a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e9e:	4741                	li	a4,16
    80005ea0:	86ce                	mv	a3,s3
    80005ea2:	f1840613          	addi	a2,s0,-232
    80005ea6:	4581                	li	a1,0
    80005ea8:	854a                	mv	a0,s2
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	300080e7          	jalr	768(ra) # 800041aa <readi>
    80005eb2:	47c1                	li	a5,16
    80005eb4:	00f51c63          	bne	a0,a5,80005ecc <sys_unlink+0x176>
    if(de.inum != 0)
    80005eb8:	f1845783          	lhu	a5,-232(s0)
    80005ebc:	e7b5                	bnez	a5,80005f28 <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ebe:	29c1                	addiw	s3,s3,16
    80005ec0:	04c92783          	lw	a5,76(s2)
    80005ec4:	fcf9ede3          	bltu	s3,a5,80005e9e <sys_unlink+0x148>
    80005ec8:	69ae                	ld	s3,200(sp)
    80005eca:	bf15                	j	80005dfe <sys_unlink+0xa8>
      panic("isdirempty: readi");
    80005ecc:	00002517          	auipc	a0,0x2
    80005ed0:	73450513          	addi	a0,a0,1844 # 80008600 <etext+0x600>
    80005ed4:	ffffa097          	auipc	ra,0xffffa
    80005ed8:	68c080e7          	jalr	1676(ra) # 80000560 <panic>
    80005edc:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005ede:	00002517          	auipc	a0,0x2
    80005ee2:	73a50513          	addi	a0,a0,1850 # 80008618 <etext+0x618>
    80005ee6:	ffffa097          	auipc	ra,0xffffa
    80005eea:	67a080e7          	jalr	1658(ra) # 80000560 <panic>
    dp->nlink--;
    80005eee:	04a4d783          	lhu	a5,74(s1)
    80005ef2:	37fd                	addiw	a5,a5,-1
    80005ef4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ef8:	8526                	mv	a0,s1
    80005efa:	ffffe097          	auipc	ra,0xffffe
    80005efe:	f2c080e7          	jalr	-212(ra) # 80003e26 <iupdate>
    80005f02:	bf0d                	j	80005e34 <sys_unlink+0xde>
    80005f04:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005f06:	8526                	mv	a0,s1
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	250080e7          	jalr	592(ra) # 80004158 <iunlockput>
  end_op();
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	a2a080e7          	jalr	-1494(ra) # 8000493a <end_op>
  return -1;
    80005f18:	557d                	li	a0,-1
    80005f1a:	64ee                	ld	s1,216(sp)
}
    80005f1c:	70ae                	ld	ra,232(sp)
    80005f1e:	740e                	ld	s0,224(sp)
    80005f20:	616d                	addi	sp,sp,240
    80005f22:	8082                	ret
    return -1;
    80005f24:	557d                	li	a0,-1
    80005f26:	bfdd                	j	80005f1c <sys_unlink+0x1c6>
    iunlockput(ip);
    80005f28:	854a                	mv	a0,s2
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	22e080e7          	jalr	558(ra) # 80004158 <iunlockput>
    goto bad;
    80005f32:	694e                	ld	s2,208(sp)
    80005f34:	69ae                	ld	s3,200(sp)
    80005f36:	bfc1                	j	80005f06 <sys_unlink+0x1b0>

0000000080005f38 <sys_open>:

uint64
sys_open(void)
{
    80005f38:	7131                	addi	sp,sp,-192
    80005f3a:	fd06                	sd	ra,184(sp)
    80005f3c:	f922                	sd	s0,176(sp)
    80005f3e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005f40:	f4c40593          	addi	a1,s0,-180
    80005f44:	4505                	li	a0,1
    80005f46:	ffffd097          	auipc	ra,0xffffd
    80005f4a:	26c080e7          	jalr	620(ra) # 800031b2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f4e:	08000613          	li	a2,128
    80005f52:	f5040593          	addi	a1,s0,-176
    80005f56:	4501                	li	a0,0
    80005f58:	ffffd097          	auipc	ra,0xffffd
    80005f5c:	29a080e7          	jalr	666(ra) # 800031f2 <argstr>
    80005f60:	87aa                	mv	a5,a0
    return -1;
    80005f62:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f64:	0a07ce63          	bltz	a5,80006020 <sys_open+0xe8>
    80005f68:	f526                	sd	s1,168(sp)

  begin_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	956080e7          	jalr	-1706(ra) # 800048c0 <begin_op>

  if(omode & O_CREATE){
    80005f72:	f4c42783          	lw	a5,-180(s0)
    80005f76:	2007f793          	andi	a5,a5,512
    80005f7a:	cfd5                	beqz	a5,80006036 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f7c:	4681                	li	a3,0
    80005f7e:	4601                	li	a2,0
    80005f80:	4589                	li	a1,2
    80005f82:	f5040513          	addi	a0,s0,-176
    80005f86:	00000097          	auipc	ra,0x0
    80005f8a:	95a080e7          	jalr	-1702(ra) # 800058e0 <create>
    80005f8e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f90:	cd41                	beqz	a0,80006028 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f92:	04449703          	lh	a4,68(s1)
    80005f96:	478d                	li	a5,3
    80005f98:	00f71763          	bne	a4,a5,80005fa6 <sys_open+0x6e>
    80005f9c:	0464d703          	lhu	a4,70(s1)
    80005fa0:	47a5                	li	a5,9
    80005fa2:	0ee7e163          	bltu	a5,a4,80006084 <sys_open+0x14c>
    80005fa6:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fa8:	fffff097          	auipc	ra,0xfffff
    80005fac:	d26080e7          	jalr	-730(ra) # 80004cce <filealloc>
    80005fb0:	892a                	mv	s2,a0
    80005fb2:	c97d                	beqz	a0,800060a8 <sys_open+0x170>
    80005fb4:	ed4e                	sd	s3,152(sp)
    80005fb6:	00000097          	auipc	ra,0x0
    80005fba:	8e8080e7          	jalr	-1816(ra) # 8000589e <fdalloc>
    80005fbe:	89aa                	mv	s3,a0
    80005fc0:	0c054e63          	bltz	a0,8000609c <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fc4:	04449703          	lh	a4,68(s1)
    80005fc8:	478d                	li	a5,3
    80005fca:	0ef70c63          	beq	a4,a5,800060c2 <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fce:	4789                	li	a5,2
    80005fd0:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005fd4:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005fd8:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005fdc:	f4c42783          	lw	a5,-180(s0)
    80005fe0:	0017c713          	xori	a4,a5,1
    80005fe4:	8b05                	andi	a4,a4,1
    80005fe6:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005fea:	0037f713          	andi	a4,a5,3
    80005fee:	00e03733          	snez	a4,a4
    80005ff2:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ff6:	4007f793          	andi	a5,a5,1024
    80005ffa:	c791                	beqz	a5,80006006 <sys_open+0xce>
    80005ffc:	04449703          	lh	a4,68(s1)
    80006000:	4789                	li	a5,2
    80006002:	0cf70763          	beq	a4,a5,800060d0 <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    80006006:	8526                	mv	a0,s1
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	fb0080e7          	jalr	-80(ra) # 80003fb8 <iunlock>
  end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	92a080e7          	jalr	-1750(ra) # 8000493a <end_op>

  return fd;
    80006018:	854e                	mv	a0,s3
    8000601a:	74aa                	ld	s1,168(sp)
    8000601c:	790a                	ld	s2,160(sp)
    8000601e:	69ea                	ld	s3,152(sp)
}
    80006020:	70ea                	ld	ra,184(sp)
    80006022:	744a                	ld	s0,176(sp)
    80006024:	6129                	addi	sp,sp,192
    80006026:	8082                	ret
      end_op();
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	912080e7          	jalr	-1774(ra) # 8000493a <end_op>
      return -1;
    80006030:	557d                	li	a0,-1
    80006032:	74aa                	ld	s1,168(sp)
    80006034:	b7f5                	j	80006020 <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    80006036:	f5040513          	addi	a0,s0,-176
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	686080e7          	jalr	1670(ra) # 800046c0 <namei>
    80006042:	84aa                	mv	s1,a0
    80006044:	c90d                	beqz	a0,80006076 <sys_open+0x13e>
    ilock(ip);
    80006046:	ffffe097          	auipc	ra,0xffffe
    8000604a:	eac080e7          	jalr	-340(ra) # 80003ef2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000604e:	04449703          	lh	a4,68(s1)
    80006052:	4785                	li	a5,1
    80006054:	f2f71fe3          	bne	a4,a5,80005f92 <sys_open+0x5a>
    80006058:	f4c42783          	lw	a5,-180(s0)
    8000605c:	d7a9                	beqz	a5,80005fa6 <sys_open+0x6e>
      iunlockput(ip);
    8000605e:	8526                	mv	a0,s1
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	0f8080e7          	jalr	248(ra) # 80004158 <iunlockput>
      end_op();
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	8d2080e7          	jalr	-1838(ra) # 8000493a <end_op>
      return -1;
    80006070:	557d                	li	a0,-1
    80006072:	74aa                	ld	s1,168(sp)
    80006074:	b775                	j	80006020 <sys_open+0xe8>
      end_op();
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	8c4080e7          	jalr	-1852(ra) # 8000493a <end_op>
      return -1;
    8000607e:	557d                	li	a0,-1
    80006080:	74aa                	ld	s1,168(sp)
    80006082:	bf79                	j	80006020 <sys_open+0xe8>
    iunlockput(ip);
    80006084:	8526                	mv	a0,s1
    80006086:	ffffe097          	auipc	ra,0xffffe
    8000608a:	0d2080e7          	jalr	210(ra) # 80004158 <iunlockput>
    end_op();
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	8ac080e7          	jalr	-1876(ra) # 8000493a <end_op>
    return -1;
    80006096:	557d                	li	a0,-1
    80006098:	74aa                	ld	s1,168(sp)
    8000609a:	b759                	j	80006020 <sys_open+0xe8>
      fileclose(f);
    8000609c:	854a                	mv	a0,s2
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	cec080e7          	jalr	-788(ra) # 80004d8a <fileclose>
    800060a6:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800060a8:	8526                	mv	a0,s1
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	0ae080e7          	jalr	174(ra) # 80004158 <iunlockput>
    end_op();
    800060b2:	fffff097          	auipc	ra,0xfffff
    800060b6:	888080e7          	jalr	-1912(ra) # 8000493a <end_op>
    return -1;
    800060ba:	557d                	li	a0,-1
    800060bc:	74aa                	ld	s1,168(sp)
    800060be:	790a                	ld	s2,160(sp)
    800060c0:	b785                	j	80006020 <sys_open+0xe8>
    f->type = FD_DEVICE;
    800060c2:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800060c6:	04649783          	lh	a5,70(s1)
    800060ca:	02f91223          	sh	a5,36(s2)
    800060ce:	b729                	j	80005fd8 <sys_open+0xa0>
    itrunc(ip);
    800060d0:	8526                	mv	a0,s1
    800060d2:	ffffe097          	auipc	ra,0xffffe
    800060d6:	f32080e7          	jalr	-206(ra) # 80004004 <itrunc>
    800060da:	b735                	j	80006006 <sys_open+0xce>

00000000800060dc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060dc:	7175                	addi	sp,sp,-144
    800060de:	e506                	sd	ra,136(sp)
    800060e0:	e122                	sd	s0,128(sp)
    800060e2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060e4:	ffffe097          	auipc	ra,0xffffe
    800060e8:	7dc080e7          	jalr	2012(ra) # 800048c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060ec:	08000613          	li	a2,128
    800060f0:	f7040593          	addi	a1,s0,-144
    800060f4:	4501                	li	a0,0
    800060f6:	ffffd097          	auipc	ra,0xffffd
    800060fa:	0fc080e7          	jalr	252(ra) # 800031f2 <argstr>
    800060fe:	02054963          	bltz	a0,80006130 <sys_mkdir+0x54>
    80006102:	4681                	li	a3,0
    80006104:	4601                	li	a2,0
    80006106:	4585                	li	a1,1
    80006108:	f7040513          	addi	a0,s0,-144
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	7d4080e7          	jalr	2004(ra) # 800058e0 <create>
    80006114:	cd11                	beqz	a0,80006130 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	042080e7          	jalr	66(ra) # 80004158 <iunlockput>
  end_op();
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	81c080e7          	jalr	-2020(ra) # 8000493a <end_op>
  return 0;
    80006126:	4501                	li	a0,0
}
    80006128:	60aa                	ld	ra,136(sp)
    8000612a:	640a                	ld	s0,128(sp)
    8000612c:	6149                	addi	sp,sp,144
    8000612e:	8082                	ret
    end_op();
    80006130:	fffff097          	auipc	ra,0xfffff
    80006134:	80a080e7          	jalr	-2038(ra) # 8000493a <end_op>
    return -1;
    80006138:	557d                	li	a0,-1
    8000613a:	b7fd                	j	80006128 <sys_mkdir+0x4c>

000000008000613c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000613c:	7135                	addi	sp,sp,-160
    8000613e:	ed06                	sd	ra,152(sp)
    80006140:	e922                	sd	s0,144(sp)
    80006142:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	77c080e7          	jalr	1916(ra) # 800048c0 <begin_op>
  argint(1, &major);
    8000614c:	f6c40593          	addi	a1,s0,-148
    80006150:	4505                	li	a0,1
    80006152:	ffffd097          	auipc	ra,0xffffd
    80006156:	060080e7          	jalr	96(ra) # 800031b2 <argint>
  argint(2, &minor);
    8000615a:	f6840593          	addi	a1,s0,-152
    8000615e:	4509                	li	a0,2
    80006160:	ffffd097          	auipc	ra,0xffffd
    80006164:	052080e7          	jalr	82(ra) # 800031b2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006168:	08000613          	li	a2,128
    8000616c:	f7040593          	addi	a1,s0,-144
    80006170:	4501                	li	a0,0
    80006172:	ffffd097          	auipc	ra,0xffffd
    80006176:	080080e7          	jalr	128(ra) # 800031f2 <argstr>
    8000617a:	02054b63          	bltz	a0,800061b0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000617e:	f6841683          	lh	a3,-152(s0)
    80006182:	f6c41603          	lh	a2,-148(s0)
    80006186:	458d                	li	a1,3
    80006188:	f7040513          	addi	a0,s0,-144
    8000618c:	fffff097          	auipc	ra,0xfffff
    80006190:	754080e7          	jalr	1876(ra) # 800058e0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006194:	cd11                	beqz	a0,800061b0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006196:	ffffe097          	auipc	ra,0xffffe
    8000619a:	fc2080e7          	jalr	-62(ra) # 80004158 <iunlockput>
  end_op();
    8000619e:	ffffe097          	auipc	ra,0xffffe
    800061a2:	79c080e7          	jalr	1948(ra) # 8000493a <end_op>
  return 0;
    800061a6:	4501                	li	a0,0
}
    800061a8:	60ea                	ld	ra,152(sp)
    800061aa:	644a                	ld	s0,144(sp)
    800061ac:	610d                	addi	sp,sp,160
    800061ae:	8082                	ret
    end_op();
    800061b0:	ffffe097          	auipc	ra,0xffffe
    800061b4:	78a080e7          	jalr	1930(ra) # 8000493a <end_op>
    return -1;
    800061b8:	557d                	li	a0,-1
    800061ba:	b7fd                	j	800061a8 <sys_mknod+0x6c>

00000000800061bc <sys_chdir>:

uint64
sys_chdir(void)
{
    800061bc:	7135                	addi	sp,sp,-160
    800061be:	ed06                	sd	ra,152(sp)
    800061c0:	e922                	sd	s0,144(sp)
    800061c2:	e14a                	sd	s2,128(sp)
    800061c4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061c6:	ffffc097          	auipc	ra,0xffffc
    800061ca:	8b4080e7          	jalr	-1868(ra) # 80001a7a <myproc>
    800061ce:	892a                	mv	s2,a0
  
  begin_op();
    800061d0:	ffffe097          	auipc	ra,0xffffe
    800061d4:	6f0080e7          	jalr	1776(ra) # 800048c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061d8:	08000613          	li	a2,128
    800061dc:	f6040593          	addi	a1,s0,-160
    800061e0:	4501                	li	a0,0
    800061e2:	ffffd097          	auipc	ra,0xffffd
    800061e6:	010080e7          	jalr	16(ra) # 800031f2 <argstr>
    800061ea:	04054d63          	bltz	a0,80006244 <sys_chdir+0x88>
    800061ee:	e526                	sd	s1,136(sp)
    800061f0:	f6040513          	addi	a0,s0,-160
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	4cc080e7          	jalr	1228(ra) # 800046c0 <namei>
    800061fc:	84aa                	mv	s1,a0
    800061fe:	c131                	beqz	a0,80006242 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	cf2080e7          	jalr	-782(ra) # 80003ef2 <ilock>
  if(ip->type != T_DIR){
    80006208:	04449703          	lh	a4,68(s1)
    8000620c:	4785                	li	a5,1
    8000620e:	04f71163          	bne	a4,a5,80006250 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006212:	8526                	mv	a0,s1
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	da4080e7          	jalr	-604(ra) # 80003fb8 <iunlock>
  iput(p->cwd);
    8000621c:	32893503          	ld	a0,808(s2)
    80006220:	ffffe097          	auipc	ra,0xffffe
    80006224:	e90080e7          	jalr	-368(ra) # 800040b0 <iput>
  end_op();
    80006228:	ffffe097          	auipc	ra,0xffffe
    8000622c:	712080e7          	jalr	1810(ra) # 8000493a <end_op>
  p->cwd = ip;
    80006230:	32993423          	sd	s1,808(s2)
  return 0;
    80006234:	4501                	li	a0,0
    80006236:	64aa                	ld	s1,136(sp)
}
    80006238:	60ea                	ld	ra,152(sp)
    8000623a:	644a                	ld	s0,144(sp)
    8000623c:	690a                	ld	s2,128(sp)
    8000623e:	610d                	addi	sp,sp,160
    80006240:	8082                	ret
    80006242:	64aa                	ld	s1,136(sp)
    end_op();
    80006244:	ffffe097          	auipc	ra,0xffffe
    80006248:	6f6080e7          	jalr	1782(ra) # 8000493a <end_op>
    return -1;
    8000624c:	557d                	li	a0,-1
    8000624e:	b7ed                	j	80006238 <sys_chdir+0x7c>
    iunlockput(ip);
    80006250:	8526                	mv	a0,s1
    80006252:	ffffe097          	auipc	ra,0xffffe
    80006256:	f06080e7          	jalr	-250(ra) # 80004158 <iunlockput>
    end_op();
    8000625a:	ffffe097          	auipc	ra,0xffffe
    8000625e:	6e0080e7          	jalr	1760(ra) # 8000493a <end_op>
    return -1;
    80006262:	557d                	li	a0,-1
    80006264:	64aa                	ld	s1,136(sp)
    80006266:	bfc9                	j	80006238 <sys_chdir+0x7c>

0000000080006268 <sys_exec>:

uint64
sys_exec(void)
{
    80006268:	7121                	addi	sp,sp,-448
    8000626a:	ff06                	sd	ra,440(sp)
    8000626c:	fb22                	sd	s0,432(sp)
    8000626e:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006270:	e4840593          	addi	a1,s0,-440
    80006274:	4505                	li	a0,1
    80006276:	ffffd097          	auipc	ra,0xffffd
    8000627a:	f5c080e7          	jalr	-164(ra) # 800031d2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000627e:	08000613          	li	a2,128
    80006282:	f5040593          	addi	a1,s0,-176
    80006286:	4501                	li	a0,0
    80006288:	ffffd097          	auipc	ra,0xffffd
    8000628c:	f6a080e7          	jalr	-150(ra) # 800031f2 <argstr>
    80006290:	87aa                	mv	a5,a0
    return -1;
    80006292:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006294:	0e07c263          	bltz	a5,80006378 <sys_exec+0x110>
    80006298:	f726                	sd	s1,424(sp)
    8000629a:	f34a                	sd	s2,416(sp)
    8000629c:	ef4e                	sd	s3,408(sp)
    8000629e:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800062a0:	10000613          	li	a2,256
    800062a4:	4581                	li	a1,0
    800062a6:	e5040513          	addi	a0,s0,-432
    800062aa:	ffffb097          	auipc	ra,0xffffb
    800062ae:	a8a080e7          	jalr	-1398(ra) # 80000d34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062b2:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800062b6:	89a6                	mv	s3,s1
    800062b8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062ba:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062be:	00391513          	slli	a0,s2,0x3
    800062c2:	e4040593          	addi	a1,s0,-448
    800062c6:	e4843783          	ld	a5,-440(s0)
    800062ca:	953e                	add	a0,a0,a5
    800062cc:	ffffd097          	auipc	ra,0xffffd
    800062d0:	e42080e7          	jalr	-446(ra) # 8000310e <fetchaddr>
    800062d4:	02054a63          	bltz	a0,80006308 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800062d8:	e4043783          	ld	a5,-448(s0)
    800062dc:	c7b9                	beqz	a5,8000632a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062de:	ffffb097          	auipc	ra,0xffffb
    800062e2:	86a080e7          	jalr	-1942(ra) # 80000b48 <kalloc>
    800062e6:	85aa                	mv	a1,a0
    800062e8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062ec:	cd11                	beqz	a0,80006308 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062ee:	6605                	lui	a2,0x1
    800062f0:	e4043503          	ld	a0,-448(s0)
    800062f4:	ffffd097          	auipc	ra,0xffffd
    800062f8:	e70080e7          	jalr	-400(ra) # 80003164 <fetchstr>
    800062fc:	00054663          	bltz	a0,80006308 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006300:	0905                	addi	s2,s2,1
    80006302:	09a1                	addi	s3,s3,8
    80006304:	fb491de3          	bne	s2,s4,800062be <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006308:	f5040913          	addi	s2,s0,-176
    8000630c:	6088                	ld	a0,0(s1)
    8000630e:	c125                	beqz	a0,8000636e <sys_exec+0x106>
    kfree(argv[i]);
    80006310:	ffffa097          	auipc	ra,0xffffa
    80006314:	73a080e7          	jalr	1850(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006318:	04a1                	addi	s1,s1,8
    8000631a:	ff2499e3          	bne	s1,s2,8000630c <sys_exec+0xa4>
  return -1;
    8000631e:	557d                	li	a0,-1
    80006320:	74ba                	ld	s1,424(sp)
    80006322:	791a                	ld	s2,416(sp)
    80006324:	69fa                	ld	s3,408(sp)
    80006326:	6a5a                	ld	s4,400(sp)
    80006328:	a881                	j	80006378 <sys_exec+0x110>
      argv[i] = 0;
    8000632a:	0009079b          	sext.w	a5,s2
    8000632e:	078e                	slli	a5,a5,0x3
    80006330:	fd078793          	addi	a5,a5,-48
    80006334:	97a2                	add	a5,a5,s0
    80006336:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    8000633a:	e5040593          	addi	a1,s0,-432
    8000633e:	f5040513          	addi	a0,s0,-176
    80006342:	fffff097          	auipc	ra,0xfffff
    80006346:	11e080e7          	jalr	286(ra) # 80005460 <exec>
    8000634a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000634c:	f5040993          	addi	s3,s0,-176
    80006350:	6088                	ld	a0,0(s1)
    80006352:	c901                	beqz	a0,80006362 <sys_exec+0xfa>
    kfree(argv[i]);
    80006354:	ffffa097          	auipc	ra,0xffffa
    80006358:	6f6080e7          	jalr	1782(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000635c:	04a1                	addi	s1,s1,8
    8000635e:	ff3499e3          	bne	s1,s3,80006350 <sys_exec+0xe8>
  return ret;
    80006362:	854a                	mv	a0,s2
    80006364:	74ba                	ld	s1,424(sp)
    80006366:	791a                	ld	s2,416(sp)
    80006368:	69fa                	ld	s3,408(sp)
    8000636a:	6a5a                	ld	s4,400(sp)
    8000636c:	a031                	j	80006378 <sys_exec+0x110>
  return -1;
    8000636e:	557d                	li	a0,-1
    80006370:	74ba                	ld	s1,424(sp)
    80006372:	791a                	ld	s2,416(sp)
    80006374:	69fa                	ld	s3,408(sp)
    80006376:	6a5a                	ld	s4,400(sp)
}
    80006378:	70fa                	ld	ra,440(sp)
    8000637a:	745a                	ld	s0,432(sp)
    8000637c:	6139                	addi	sp,sp,448
    8000637e:	8082                	ret

0000000080006380 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006380:	7139                	addi	sp,sp,-64
    80006382:	fc06                	sd	ra,56(sp)
    80006384:	f822                	sd	s0,48(sp)
    80006386:	f426                	sd	s1,40(sp)
    80006388:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000638a:	ffffb097          	auipc	ra,0xffffb
    8000638e:	6f0080e7          	jalr	1776(ra) # 80001a7a <myproc>
    80006392:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006394:	fd840593          	addi	a1,s0,-40
    80006398:	4501                	li	a0,0
    8000639a:	ffffd097          	auipc	ra,0xffffd
    8000639e:	e38080e7          	jalr	-456(ra) # 800031d2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800063a2:	fc840593          	addi	a1,s0,-56
    800063a6:	fd040513          	addi	a0,s0,-48
    800063aa:	fffff097          	auipc	ra,0xfffff
    800063ae:	d4e080e7          	jalr	-690(ra) # 800050f8 <pipealloc>
    return -1;
    800063b2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063b4:	0c054963          	bltz	a0,80006486 <sys_pipe+0x106>
  fd0 = -1;
    800063b8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063bc:	fd043503          	ld	a0,-48(s0)
    800063c0:	fffff097          	auipc	ra,0xfffff
    800063c4:	4de080e7          	jalr	1246(ra) # 8000589e <fdalloc>
    800063c8:	fca42223          	sw	a0,-60(s0)
    800063cc:	0a054063          	bltz	a0,8000646c <sys_pipe+0xec>
    800063d0:	fc843503          	ld	a0,-56(s0)
    800063d4:	fffff097          	auipc	ra,0xfffff
    800063d8:	4ca080e7          	jalr	1226(ra) # 8000589e <fdalloc>
    800063dc:	fca42023          	sw	a0,-64(s0)
    800063e0:	06054c63          	bltz	a0,80006458 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063e4:	4691                	li	a3,4
    800063e6:	fc440613          	addi	a2,s0,-60
    800063ea:	fd843583          	ld	a1,-40(s0)
    800063ee:	2284b503          	ld	a0,552(s1)
    800063f2:	ffffb097          	auipc	ra,0xffffb
    800063f6:	2f0080e7          	jalr	752(ra) # 800016e2 <copyout>
    800063fa:	02054163          	bltz	a0,8000641c <sys_pipe+0x9c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800063fe:	4691                	li	a3,4
    80006400:	fc040613          	addi	a2,s0,-64
    80006404:	fd843583          	ld	a1,-40(s0)
    80006408:	0591                	addi	a1,a1,4
    8000640a:	2284b503          	ld	a0,552(s1)
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	2d4080e7          	jalr	724(ra) # 800016e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006416:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006418:	06055763          	bgez	a0,80006486 <sys_pipe+0x106>
    p->ofile[fd0] = 0;
    8000641c:	fc442783          	lw	a5,-60(s0)
    80006420:	05478793          	addi	a5,a5,84
    80006424:	078e                	slli	a5,a5,0x3
    80006426:	97a6                	add	a5,a5,s1
    80006428:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000642c:	fc042783          	lw	a5,-64(s0)
    80006430:	05478793          	addi	a5,a5,84
    80006434:	078e                	slli	a5,a5,0x3
    80006436:	94be                	add	s1,s1,a5
    80006438:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    8000643c:	fd043503          	ld	a0,-48(s0)
    80006440:	fffff097          	auipc	ra,0xfffff
    80006444:	94a080e7          	jalr	-1718(ra) # 80004d8a <fileclose>
    fileclose(wf);
    80006448:	fc843503          	ld	a0,-56(s0)
    8000644c:	fffff097          	auipc	ra,0xfffff
    80006450:	93e080e7          	jalr	-1730(ra) # 80004d8a <fileclose>
    return -1;
    80006454:	57fd                	li	a5,-1
    80006456:	a805                	j	80006486 <sys_pipe+0x106>
    if(fd0 >= 0)
    80006458:	fc442783          	lw	a5,-60(s0)
    8000645c:	0007c863          	bltz	a5,8000646c <sys_pipe+0xec>
      p->ofile[fd0] = 0;
    80006460:	05478793          	addi	a5,a5,84
    80006464:	078e                	slli	a5,a5,0x3
    80006466:	97a6                	add	a5,a5,s1
    80006468:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    8000646c:	fd043503          	ld	a0,-48(s0)
    80006470:	fffff097          	auipc	ra,0xfffff
    80006474:	91a080e7          	jalr	-1766(ra) # 80004d8a <fileclose>
    fileclose(wf);
    80006478:	fc843503          	ld	a0,-56(s0)
    8000647c:	fffff097          	auipc	ra,0xfffff
    80006480:	90e080e7          	jalr	-1778(ra) # 80004d8a <fileclose>
    return -1;
    80006484:	57fd                	li	a5,-1
}
    80006486:	853e                	mv	a0,a5
    80006488:	70e2                	ld	ra,56(sp)
    8000648a:	7442                	ld	s0,48(sp)
    8000648c:	74a2                	ld	s1,40(sp)
    8000648e:	6121                	addi	sp,sp,64
    80006490:	8082                	ret
	...

00000000800064a0 <kernelvec>:
    800064a0:	7111                	addi	sp,sp,-256
    800064a2:	e006                	sd	ra,0(sp)
    800064a4:	e40a                	sd	sp,8(sp)
    800064a6:	e80e                	sd	gp,16(sp)
    800064a8:	ec12                	sd	tp,24(sp)
    800064aa:	f016                	sd	t0,32(sp)
    800064ac:	f41a                	sd	t1,40(sp)
    800064ae:	f81e                	sd	t2,48(sp)
    800064b0:	fc22                	sd	s0,56(sp)
    800064b2:	e0a6                	sd	s1,64(sp)
    800064b4:	e4aa                	sd	a0,72(sp)
    800064b6:	e8ae                	sd	a1,80(sp)
    800064b8:	ecb2                	sd	a2,88(sp)
    800064ba:	f0b6                	sd	a3,96(sp)
    800064bc:	f4ba                	sd	a4,104(sp)
    800064be:	f8be                	sd	a5,112(sp)
    800064c0:	fcc2                	sd	a6,120(sp)
    800064c2:	e146                	sd	a7,128(sp)
    800064c4:	e54a                	sd	s2,136(sp)
    800064c6:	e94e                	sd	s3,144(sp)
    800064c8:	ed52                	sd	s4,152(sp)
    800064ca:	f156                	sd	s5,160(sp)
    800064cc:	f55a                	sd	s6,168(sp)
    800064ce:	f95e                	sd	s7,176(sp)
    800064d0:	fd62                	sd	s8,184(sp)
    800064d2:	e1e6                	sd	s9,192(sp)
    800064d4:	e5ea                	sd	s10,200(sp)
    800064d6:	e9ee                	sd	s11,208(sp)
    800064d8:	edf2                	sd	t3,216(sp)
    800064da:	f1f6                	sd	t4,224(sp)
    800064dc:	f5fa                	sd	t5,232(sp)
    800064de:	f9fe                	sd	t6,240(sp)
    800064e0:	aeffc0ef          	jal	80002fce <kerneltrap>
    800064e4:	6082                	ld	ra,0(sp)
    800064e6:	6122                	ld	sp,8(sp)
    800064e8:	61c2                	ld	gp,16(sp)
    800064ea:	7282                	ld	t0,32(sp)
    800064ec:	7322                	ld	t1,40(sp)
    800064ee:	73c2                	ld	t2,48(sp)
    800064f0:	7462                	ld	s0,56(sp)
    800064f2:	6486                	ld	s1,64(sp)
    800064f4:	6526                	ld	a0,72(sp)
    800064f6:	65c6                	ld	a1,80(sp)
    800064f8:	6666                	ld	a2,88(sp)
    800064fa:	7686                	ld	a3,96(sp)
    800064fc:	7726                	ld	a4,104(sp)
    800064fe:	77c6                	ld	a5,112(sp)
    80006500:	7866                	ld	a6,120(sp)
    80006502:	688a                	ld	a7,128(sp)
    80006504:	692a                	ld	s2,136(sp)
    80006506:	69ca                	ld	s3,144(sp)
    80006508:	6a6a                	ld	s4,152(sp)
    8000650a:	7a8a                	ld	s5,160(sp)
    8000650c:	7b2a                	ld	s6,168(sp)
    8000650e:	7bca                	ld	s7,176(sp)
    80006510:	7c6a                	ld	s8,184(sp)
    80006512:	6c8e                	ld	s9,192(sp)
    80006514:	6d2e                	ld	s10,200(sp)
    80006516:	6dce                	ld	s11,208(sp)
    80006518:	6e6e                	ld	t3,216(sp)
    8000651a:	7e8e                	ld	t4,224(sp)
    8000651c:	7f2e                	ld	t5,232(sp)
    8000651e:	7fce                	ld	t6,240(sp)
    80006520:	6111                	addi	sp,sp,256
    80006522:	10200073          	sret
    80006526:	00000013          	nop
    8000652a:	00000013          	nop
    8000652e:	0001                	nop

0000000080006530 <timervec>:
    80006530:	34051573          	csrrw	a0,mscratch,a0
    80006534:	e10c                	sd	a1,0(a0)
    80006536:	e510                	sd	a2,8(a0)
    80006538:	e914                	sd	a3,16(a0)
    8000653a:	6d0c                	ld	a1,24(a0)
    8000653c:	7110                	ld	a2,32(a0)
    8000653e:	6194                	ld	a3,0(a1)
    80006540:	96b2                	add	a3,a3,a2
    80006542:	e194                	sd	a3,0(a1)
    80006544:	4589                	li	a1,2
    80006546:	14459073          	csrw	sip,a1
    8000654a:	6914                	ld	a3,16(a0)
    8000654c:	6510                	ld	a2,8(a0)
    8000654e:	610c                	ld	a1,0(a0)
    80006550:	34051573          	csrrw	a0,mscratch,a0
    80006554:	30200073          	mret
	...

000000008000655a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000655a:	1141                	addi	sp,sp,-16
    8000655c:	e422                	sd	s0,8(sp)
    8000655e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006560:	0c0007b7          	lui	a5,0xc000
    80006564:	4705                	li	a4,1
    80006566:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006568:	0c0007b7          	lui	a5,0xc000
    8000656c:	c3d8                	sw	a4,4(a5)
}
    8000656e:	6422                	ld	s0,8(sp)
    80006570:	0141                	addi	sp,sp,16
    80006572:	8082                	ret

0000000080006574 <plicinithart>:

void
plicinithart(void)
{
    80006574:	1141                	addi	sp,sp,-16
    80006576:	e406                	sd	ra,8(sp)
    80006578:	e022                	sd	s0,0(sp)
    8000657a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000657c:	ffffb097          	auipc	ra,0xffffb
    80006580:	4d2080e7          	jalr	1234(ra) # 80001a4e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006584:	0085171b          	slliw	a4,a0,0x8
    80006588:	0c0027b7          	lui	a5,0xc002
    8000658c:	97ba                	add	a5,a5,a4
    8000658e:	40200713          	li	a4,1026
    80006592:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006596:	00d5151b          	slliw	a0,a0,0xd
    8000659a:	0c2017b7          	lui	a5,0xc201
    8000659e:	97aa                	add	a5,a5,a0
    800065a0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800065a4:	60a2                	ld	ra,8(sp)
    800065a6:	6402                	ld	s0,0(sp)
    800065a8:	0141                	addi	sp,sp,16
    800065aa:	8082                	ret

00000000800065ac <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800065ac:	1141                	addi	sp,sp,-16
    800065ae:	e406                	sd	ra,8(sp)
    800065b0:	e022                	sd	s0,0(sp)
    800065b2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065b4:	ffffb097          	auipc	ra,0xffffb
    800065b8:	49a080e7          	jalr	1178(ra) # 80001a4e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800065bc:	00d5151b          	slliw	a0,a0,0xd
    800065c0:	0c2017b7          	lui	a5,0xc201
    800065c4:	97aa                	add	a5,a5,a0
  return irq;
}
    800065c6:	43c8                	lw	a0,4(a5)
    800065c8:	60a2                	ld	ra,8(sp)
    800065ca:	6402                	ld	s0,0(sp)
    800065cc:	0141                	addi	sp,sp,16
    800065ce:	8082                	ret

00000000800065d0 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065d0:	1101                	addi	sp,sp,-32
    800065d2:	ec06                	sd	ra,24(sp)
    800065d4:	e822                	sd	s0,16(sp)
    800065d6:	e426                	sd	s1,8(sp)
    800065d8:	1000                	addi	s0,sp,32
    800065da:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065dc:	ffffb097          	auipc	ra,0xffffb
    800065e0:	472080e7          	jalr	1138(ra) # 80001a4e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065e4:	00d5151b          	slliw	a0,a0,0xd
    800065e8:	0c2017b7          	lui	a5,0xc201
    800065ec:	97aa                	add	a5,a5,a0
    800065ee:	c3c4                	sw	s1,4(a5)
}
    800065f0:	60e2                	ld	ra,24(sp)
    800065f2:	6442                	ld	s0,16(sp)
    800065f4:	64a2                	ld	s1,8(sp)
    800065f6:	6105                	addi	sp,sp,32
    800065f8:	8082                	ret

00000000800065fa <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065fa:	1141                	addi	sp,sp,-16
    800065fc:	e406                	sd	ra,8(sp)
    800065fe:	e022                	sd	s0,0(sp)
    80006600:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006602:	479d                	li	a5,7
    80006604:	04a7cc63          	blt	a5,a0,8000665c <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006608:	00026797          	auipc	a5,0x26
    8000660c:	33878793          	addi	a5,a5,824 # 8002c940 <disk>
    80006610:	97aa                	add	a5,a5,a0
    80006612:	0187c783          	lbu	a5,24(a5)
    80006616:	ebb9                	bnez	a5,8000666c <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006618:	00451693          	slli	a3,a0,0x4
    8000661c:	00026797          	auipc	a5,0x26
    80006620:	32478793          	addi	a5,a5,804 # 8002c940 <disk>
    80006624:	6398                	ld	a4,0(a5)
    80006626:	9736                	add	a4,a4,a3
    80006628:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    8000662c:	6398                	ld	a4,0(a5)
    8000662e:	9736                	add	a4,a4,a3
    80006630:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006634:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006638:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    8000663c:	97aa                	add	a5,a5,a0
    8000663e:	4705                	li	a4,1
    80006640:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006644:	00026517          	auipc	a0,0x26
    80006648:	31450513          	addi	a0,a0,788 # 8002c958 <disk+0x18>
    8000664c:	ffffc097          	auipc	ra,0xffffc
    80006650:	efc080e7          	jalr	-260(ra) # 80002548 <wakeup>
}
    80006654:	60a2                	ld	ra,8(sp)
    80006656:	6402                	ld	s0,0(sp)
    80006658:	0141                	addi	sp,sp,16
    8000665a:	8082                	ret
    panic("free_desc 1");
    8000665c:	00002517          	auipc	a0,0x2
    80006660:	fcc50513          	addi	a0,a0,-52 # 80008628 <etext+0x628>
    80006664:	ffffa097          	auipc	ra,0xffffa
    80006668:	efc080e7          	jalr	-260(ra) # 80000560 <panic>
    panic("free_desc 2");
    8000666c:	00002517          	auipc	a0,0x2
    80006670:	fcc50513          	addi	a0,a0,-52 # 80008638 <etext+0x638>
    80006674:	ffffa097          	auipc	ra,0xffffa
    80006678:	eec080e7          	jalr	-276(ra) # 80000560 <panic>

000000008000667c <virtio_disk_init>:
{
    8000667c:	1101                	addi	sp,sp,-32
    8000667e:	ec06                	sd	ra,24(sp)
    80006680:	e822                	sd	s0,16(sp)
    80006682:	e426                	sd	s1,8(sp)
    80006684:	e04a                	sd	s2,0(sp)
    80006686:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006688:	00002597          	auipc	a1,0x2
    8000668c:	fc058593          	addi	a1,a1,-64 # 80008648 <etext+0x648>
    80006690:	00026517          	auipc	a0,0x26
    80006694:	3d850513          	addi	a0,a0,984 # 8002ca68 <disk+0x128>
    80006698:	ffffa097          	auipc	ra,0xffffa
    8000669c:	510080e7          	jalr	1296(ra) # 80000ba8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066a0:	100017b7          	lui	a5,0x10001
    800066a4:	4398                	lw	a4,0(a5)
    800066a6:	2701                	sext.w	a4,a4
    800066a8:	747277b7          	lui	a5,0x74727
    800066ac:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066b0:	18f71c63          	bne	a4,a5,80006848 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800066b4:	100017b7          	lui	a5,0x10001
    800066b8:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    800066ba:	439c                	lw	a5,0(a5)
    800066bc:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066be:	4709                	li	a4,2
    800066c0:	18e79463          	bne	a5,a4,80006848 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066c4:	100017b7          	lui	a5,0x10001
    800066c8:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    800066ca:	439c                	lw	a5,0(a5)
    800066cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800066ce:	16e79d63          	bne	a5,a4,80006848 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066d2:	100017b7          	lui	a5,0x10001
    800066d6:	47d8                	lw	a4,12(a5)
    800066d8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066da:	554d47b7          	lui	a5,0x554d4
    800066de:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066e2:	16f71363          	bne	a4,a5,80006848 <virtio_disk_init+0x1cc>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066e6:	100017b7          	lui	a5,0x10001
    800066ea:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066ee:	4705                	li	a4,1
    800066f0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f2:	470d                	li	a4,3
    800066f4:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066f6:	10001737          	lui	a4,0x10001
    800066fa:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066fc:	c7ffe737          	lui	a4,0xc7ffe
    80006700:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd1cdf>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006704:	8ef9                	and	a3,a3,a4
    80006706:	10001737          	lui	a4,0x10001
    8000670a:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000670c:	472d                	li	a4,11
    8000670e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006710:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80006714:	439c                	lw	a5,0(a5)
    80006716:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    8000671a:	8ba1                	andi	a5,a5,8
    8000671c:	12078e63          	beqz	a5,80006858 <virtio_disk_init+0x1dc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006720:	100017b7          	lui	a5,0x10001
    80006724:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006728:	100017b7          	lui	a5,0x10001
    8000672c:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80006730:	439c                	lw	a5,0(a5)
    80006732:	2781                	sext.w	a5,a5
    80006734:	12079a63          	bnez	a5,80006868 <virtio_disk_init+0x1ec>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006738:	100017b7          	lui	a5,0x10001
    8000673c:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80006740:	439c                	lw	a5,0(a5)
    80006742:	2781                	sext.w	a5,a5
  if(max == 0)
    80006744:	12078a63          	beqz	a5,80006878 <virtio_disk_init+0x1fc>
  if(max < NUM)
    80006748:	471d                	li	a4,7
    8000674a:	12f77f63          	bgeu	a4,a5,80006888 <virtio_disk_init+0x20c>
  disk.desc = kalloc();
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	3fa080e7          	jalr	1018(ra) # 80000b48 <kalloc>
    80006756:	00026497          	auipc	s1,0x26
    8000675a:	1ea48493          	addi	s1,s1,490 # 8002c940 <disk>
    8000675e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006760:	ffffa097          	auipc	ra,0xffffa
    80006764:	3e8080e7          	jalr	1000(ra) # 80000b48 <kalloc>
    80006768:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000676a:	ffffa097          	auipc	ra,0xffffa
    8000676e:	3de080e7          	jalr	990(ra) # 80000b48 <kalloc>
    80006772:	87aa                	mv	a5,a0
    80006774:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006776:	6088                	ld	a0,0(s1)
    80006778:	12050063          	beqz	a0,80006898 <virtio_disk_init+0x21c>
    8000677c:	00026717          	auipc	a4,0x26
    80006780:	1cc73703          	ld	a4,460(a4) # 8002c948 <disk+0x8>
    80006784:	10070a63          	beqz	a4,80006898 <virtio_disk_init+0x21c>
    80006788:	10078863          	beqz	a5,80006898 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    8000678c:	6605                	lui	a2,0x1
    8000678e:	4581                	li	a1,0
    80006790:	ffffa097          	auipc	ra,0xffffa
    80006794:	5a4080e7          	jalr	1444(ra) # 80000d34 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006798:	00026497          	auipc	s1,0x26
    8000679c:	1a848493          	addi	s1,s1,424 # 8002c940 <disk>
    800067a0:	6605                	lui	a2,0x1
    800067a2:	4581                	li	a1,0
    800067a4:	6488                	ld	a0,8(s1)
    800067a6:	ffffa097          	auipc	ra,0xffffa
    800067aa:	58e080e7          	jalr	1422(ra) # 80000d34 <memset>
  memset(disk.used, 0, PGSIZE);
    800067ae:	6605                	lui	a2,0x1
    800067b0:	4581                	li	a1,0
    800067b2:	6888                	ld	a0,16(s1)
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	580080e7          	jalr	1408(ra) # 80000d34 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800067bc:	100017b7          	lui	a5,0x10001
    800067c0:	4721                	li	a4,8
    800067c2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800067c4:	4098                	lw	a4,0(s1)
    800067c6:	100017b7          	lui	a5,0x10001
    800067ca:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800067ce:	40d8                	lw	a4,4(s1)
    800067d0:	100017b7          	lui	a5,0x10001
    800067d4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800067d8:	649c                	ld	a5,8(s1)
    800067da:	0007869b          	sext.w	a3,a5
    800067de:	10001737          	lui	a4,0x10001
    800067e2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800067e6:	9781                	srai	a5,a5,0x20
    800067e8:	10001737          	lui	a4,0x10001
    800067ec:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800067f0:	689c                	ld	a5,16(s1)
    800067f2:	0007869b          	sext.w	a3,a5
    800067f6:	10001737          	lui	a4,0x10001
    800067fa:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800067fe:	9781                	srai	a5,a5,0x20
    80006800:	10001737          	lui	a4,0x10001
    80006804:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006808:	10001737          	lui	a4,0x10001
    8000680c:	4785                	li	a5,1
    8000680e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006810:	00f48c23          	sb	a5,24(s1)
    80006814:	00f48ca3          	sb	a5,25(s1)
    80006818:	00f48d23          	sb	a5,26(s1)
    8000681c:	00f48da3          	sb	a5,27(s1)
    80006820:	00f48e23          	sb	a5,28(s1)
    80006824:	00f48ea3          	sb	a5,29(s1)
    80006828:	00f48f23          	sb	a5,30(s1)
    8000682c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006830:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006834:	100017b7          	lui	a5,0x10001
    80006838:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    8000683c:	60e2                	ld	ra,24(sp)
    8000683e:	6442                	ld	s0,16(sp)
    80006840:	64a2                	ld	s1,8(sp)
    80006842:	6902                	ld	s2,0(sp)
    80006844:	6105                	addi	sp,sp,32
    80006846:	8082                	ret
    panic("could not find virtio disk");
    80006848:	00002517          	auipc	a0,0x2
    8000684c:	e1050513          	addi	a0,a0,-496 # 80008658 <etext+0x658>
    80006850:	ffffa097          	auipc	ra,0xffffa
    80006854:	d10080e7          	jalr	-752(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006858:	00002517          	auipc	a0,0x2
    8000685c:	e2050513          	addi	a0,a0,-480 # 80008678 <etext+0x678>
    80006860:	ffffa097          	auipc	ra,0xffffa
    80006864:	d00080e7          	jalr	-768(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    80006868:	00002517          	auipc	a0,0x2
    8000686c:	e3050513          	addi	a0,a0,-464 # 80008698 <etext+0x698>
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	cf0080e7          	jalr	-784(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    80006878:	00002517          	auipc	a0,0x2
    8000687c:	e4050513          	addi	a0,a0,-448 # 800086b8 <etext+0x6b8>
    80006880:	ffffa097          	auipc	ra,0xffffa
    80006884:	ce0080e7          	jalr	-800(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    80006888:	00002517          	auipc	a0,0x2
    8000688c:	e5050513          	addi	a0,a0,-432 # 800086d8 <etext+0x6d8>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	cd0080e7          	jalr	-816(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    80006898:	00002517          	auipc	a0,0x2
    8000689c:	e6050513          	addi	a0,a0,-416 # 800086f8 <etext+0x6f8>
    800068a0:	ffffa097          	auipc	ra,0xffffa
    800068a4:	cc0080e7          	jalr	-832(ra) # 80000560 <panic>

00000000800068a8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800068a8:	7159                	addi	sp,sp,-112
    800068aa:	f486                	sd	ra,104(sp)
    800068ac:	f0a2                	sd	s0,96(sp)
    800068ae:	eca6                	sd	s1,88(sp)
    800068b0:	e8ca                	sd	s2,80(sp)
    800068b2:	e4ce                	sd	s3,72(sp)
    800068b4:	e0d2                	sd	s4,64(sp)
    800068b6:	fc56                	sd	s5,56(sp)
    800068b8:	f85a                	sd	s6,48(sp)
    800068ba:	f45e                	sd	s7,40(sp)
    800068bc:	f062                	sd	s8,32(sp)
    800068be:	ec66                	sd	s9,24(sp)
    800068c0:	1880                	addi	s0,sp,112
    800068c2:	8a2a                	mv	s4,a0
    800068c4:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800068c6:	00c52c83          	lw	s9,12(a0)
    800068ca:	001c9c9b          	slliw	s9,s9,0x1
    800068ce:	1c82                	slli	s9,s9,0x20
    800068d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800068d4:	00026517          	auipc	a0,0x26
    800068d8:	19450513          	addi	a0,a0,404 # 8002ca68 <disk+0x128>
    800068dc:	ffffa097          	auipc	ra,0xffffa
    800068e0:	35c080e7          	jalr	860(ra) # 80000c38 <acquire>
  for(int i = 0; i < 3; i++){
    800068e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800068e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800068e8:	00026b17          	auipc	s6,0x26
    800068ec:	058b0b13          	addi	s6,s6,88 # 8002c940 <disk>
  for(int i = 0; i < 3; i++){
    800068f0:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068f2:	00026c17          	auipc	s8,0x26
    800068f6:	176c0c13          	addi	s8,s8,374 # 8002ca68 <disk+0x128>
    800068fa:	a0ad                	j	80006964 <virtio_disk_rw+0xbc>
      disk.free[i] = 0;
    800068fc:	00fb0733          	add	a4,s6,a5
    80006900:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006904:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006906:	0207c563          	bltz	a5,80006930 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000690a:	2905                	addiw	s2,s2,1
    8000690c:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000690e:	05590f63          	beq	s2,s5,8000696c <virtio_disk_rw+0xc4>
    idx[i] = alloc_desc();
    80006912:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006914:	00026717          	auipc	a4,0x26
    80006918:	02c70713          	addi	a4,a4,44 # 8002c940 <disk>
    8000691c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000691e:	01874683          	lbu	a3,24(a4)
    80006922:	fee9                	bnez	a3,800068fc <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80006924:	2785                	addiw	a5,a5,1
    80006926:	0705                	addi	a4,a4,1
    80006928:	fe979be3          	bne	a5,s1,8000691e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000692c:	57fd                	li	a5,-1
    8000692e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006930:	03205163          	blez	s2,80006952 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006934:	f9042503          	lw	a0,-112(s0)
    80006938:	00000097          	auipc	ra,0x0
    8000693c:	cc2080e7          	jalr	-830(ra) # 800065fa <free_desc>
      for(int j = 0; j < i; j++)
    80006940:	4785                	li	a5,1
    80006942:	0127d863          	bge	a5,s2,80006952 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006946:	f9442503          	lw	a0,-108(s0)
    8000694a:	00000097          	auipc	ra,0x0
    8000694e:	cb0080e7          	jalr	-848(ra) # 800065fa <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006952:	85e2                	mv	a1,s8
    80006954:	00026517          	auipc	a0,0x26
    80006958:	00450513          	addi	a0,a0,4 # 8002c958 <disk+0x18>
    8000695c:	ffffc097          	auipc	ra,0xffffc
    80006960:	b88080e7          	jalr	-1144(ra) # 800024e4 <sleep>
  for(int i = 0; i < 3; i++){
    80006964:	f9040613          	addi	a2,s0,-112
    80006968:	894e                	mv	s2,s3
    8000696a:	b765                	j	80006912 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000696c:	f9042503          	lw	a0,-112(s0)
    80006970:	00451693          	slli	a3,a0,0x4

  if(write)
    80006974:	00026797          	auipc	a5,0x26
    80006978:	fcc78793          	addi	a5,a5,-52 # 8002c940 <disk>
    8000697c:	00a50713          	addi	a4,a0,10
    80006980:	0712                	slli	a4,a4,0x4
    80006982:	973e                	add	a4,a4,a5
    80006984:	01703633          	snez	a2,s7
    80006988:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000698a:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    8000698e:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006992:	6398                	ld	a4,0(a5)
    80006994:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006996:	0a868613          	addi	a2,a3,168
    8000699a:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000699c:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000699e:	6390                	ld	a2,0(a5)
    800069a0:	00d605b3          	add	a1,a2,a3
    800069a4:	4741                	li	a4,16
    800069a6:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800069a8:	4805                	li	a6,1
    800069aa:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    800069ae:	f9442703          	lw	a4,-108(s0)
    800069b2:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800069b6:	0712                	slli	a4,a4,0x4
    800069b8:	963a                	add	a2,a2,a4
    800069ba:	058a0593          	addi	a1,s4,88
    800069be:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800069c0:	0007b883          	ld	a7,0(a5)
    800069c4:	9746                	add	a4,a4,a7
    800069c6:	40000613          	li	a2,1024
    800069ca:	c710                	sw	a2,8(a4)
  if(write)
    800069cc:	001bb613          	seqz	a2,s7
    800069d0:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800069d4:	00166613          	ori	a2,a2,1
    800069d8:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800069dc:	f9842583          	lw	a1,-104(s0)
    800069e0:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069e4:	00250613          	addi	a2,a0,2
    800069e8:	0612                	slli	a2,a2,0x4
    800069ea:	963e                	add	a2,a2,a5
    800069ec:	577d                	li	a4,-1
    800069ee:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069f2:	0592                	slli	a1,a1,0x4
    800069f4:	98ae                	add	a7,a7,a1
    800069f6:	03068713          	addi	a4,a3,48
    800069fa:	973e                	add	a4,a4,a5
    800069fc:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006a00:	6398                	ld	a4,0(a5)
    80006a02:	972e                	add	a4,a4,a1
    80006a04:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006a08:	4689                	li	a3,2
    80006a0a:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80006a0e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006a12:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006a16:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a1a:	6794                	ld	a3,8(a5)
    80006a1c:	0026d703          	lhu	a4,2(a3)
    80006a20:	8b1d                	andi	a4,a4,7
    80006a22:	0706                	slli	a4,a4,0x1
    80006a24:	96ba                	add	a3,a3,a4
    80006a26:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006a2a:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a2e:	6798                	ld	a4,8(a5)
    80006a30:	00275783          	lhu	a5,2(a4)
    80006a34:	2785                	addiw	a5,a5,1
    80006a36:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a3a:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a3e:	100017b7          	lui	a5,0x10001
    80006a42:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a46:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006a4a:	00026917          	auipc	s2,0x26
    80006a4e:	01e90913          	addi	s2,s2,30 # 8002ca68 <disk+0x128>
  while(b->disk == 1) {
    80006a52:	4485                	li	s1,1
    80006a54:	01079c63          	bne	a5,a6,80006a6c <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006a58:	85ca                	mv	a1,s2
    80006a5a:	8552                	mv	a0,s4
    80006a5c:	ffffc097          	auipc	ra,0xffffc
    80006a60:	a88080e7          	jalr	-1400(ra) # 800024e4 <sleep>
  while(b->disk == 1) {
    80006a64:	004a2783          	lw	a5,4(s4)
    80006a68:	fe9788e3          	beq	a5,s1,80006a58 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006a6c:	f9042903          	lw	s2,-112(s0)
    80006a70:	00290713          	addi	a4,s2,2
    80006a74:	0712                	slli	a4,a4,0x4
    80006a76:	00026797          	auipc	a5,0x26
    80006a7a:	eca78793          	addi	a5,a5,-310 # 8002c940 <disk>
    80006a7e:	97ba                	add	a5,a5,a4
    80006a80:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006a84:	00026997          	auipc	s3,0x26
    80006a88:	ebc98993          	addi	s3,s3,-324 # 8002c940 <disk>
    80006a8c:	00491713          	slli	a4,s2,0x4
    80006a90:	0009b783          	ld	a5,0(s3)
    80006a94:	97ba                	add	a5,a5,a4
    80006a96:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a9a:	854a                	mv	a0,s2
    80006a9c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006aa0:	00000097          	auipc	ra,0x0
    80006aa4:	b5a080e7          	jalr	-1190(ra) # 800065fa <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006aa8:	8885                	andi	s1,s1,1
    80006aaa:	f0ed                	bnez	s1,80006a8c <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006aac:	00026517          	auipc	a0,0x26
    80006ab0:	fbc50513          	addi	a0,a0,-68 # 8002ca68 <disk+0x128>
    80006ab4:	ffffa097          	auipc	ra,0xffffa
    80006ab8:	238080e7          	jalr	568(ra) # 80000cec <release>
}
    80006abc:	70a6                	ld	ra,104(sp)
    80006abe:	7406                	ld	s0,96(sp)
    80006ac0:	64e6                	ld	s1,88(sp)
    80006ac2:	6946                	ld	s2,80(sp)
    80006ac4:	69a6                	ld	s3,72(sp)
    80006ac6:	6a06                	ld	s4,64(sp)
    80006ac8:	7ae2                	ld	s5,56(sp)
    80006aca:	7b42                	ld	s6,48(sp)
    80006acc:	7ba2                	ld	s7,40(sp)
    80006ace:	7c02                	ld	s8,32(sp)
    80006ad0:	6ce2                	ld	s9,24(sp)
    80006ad2:	6165                	addi	sp,sp,112
    80006ad4:	8082                	ret

0000000080006ad6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006ad6:	1101                	addi	sp,sp,-32
    80006ad8:	ec06                	sd	ra,24(sp)
    80006ada:	e822                	sd	s0,16(sp)
    80006adc:	e426                	sd	s1,8(sp)
    80006ade:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006ae0:	00026497          	auipc	s1,0x26
    80006ae4:	e6048493          	addi	s1,s1,-416 # 8002c940 <disk>
    80006ae8:	00026517          	auipc	a0,0x26
    80006aec:	f8050513          	addi	a0,a0,-128 # 8002ca68 <disk+0x128>
    80006af0:	ffffa097          	auipc	ra,0xffffa
    80006af4:	148080e7          	jalr	328(ra) # 80000c38 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006af8:	100017b7          	lui	a5,0x10001
    80006afc:	53b8                	lw	a4,96(a5)
    80006afe:	8b0d                	andi	a4,a4,3
    80006b00:	100017b7          	lui	a5,0x10001
    80006b04:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006b06:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b0a:	689c                	ld	a5,16(s1)
    80006b0c:	0204d703          	lhu	a4,32(s1)
    80006b10:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006b14:	04f70863          	beq	a4,a5,80006b64 <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006b18:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b1c:	6898                	ld	a4,16(s1)
    80006b1e:	0204d783          	lhu	a5,32(s1)
    80006b22:	8b9d                	andi	a5,a5,7
    80006b24:	078e                	slli	a5,a5,0x3
    80006b26:	97ba                	add	a5,a5,a4
    80006b28:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b2a:	00278713          	addi	a4,a5,2
    80006b2e:	0712                	slli	a4,a4,0x4
    80006b30:	9726                	add	a4,a4,s1
    80006b32:	01074703          	lbu	a4,16(a4)
    80006b36:	e721                	bnez	a4,80006b7e <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b38:	0789                	addi	a5,a5,2
    80006b3a:	0792                	slli	a5,a5,0x4
    80006b3c:	97a6                	add	a5,a5,s1
    80006b3e:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006b40:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b44:	ffffc097          	auipc	ra,0xffffc
    80006b48:	a04080e7          	jalr	-1532(ra) # 80002548 <wakeup>

    disk.used_idx += 1;
    80006b4c:	0204d783          	lhu	a5,32(s1)
    80006b50:	2785                	addiw	a5,a5,1
    80006b52:	17c2                	slli	a5,a5,0x30
    80006b54:	93c1                	srli	a5,a5,0x30
    80006b56:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b5a:	6898                	ld	a4,16(s1)
    80006b5c:	00275703          	lhu	a4,2(a4)
    80006b60:	faf71ce3          	bne	a4,a5,80006b18 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    80006b64:	00026517          	auipc	a0,0x26
    80006b68:	f0450513          	addi	a0,a0,-252 # 8002ca68 <disk+0x128>
    80006b6c:	ffffa097          	auipc	ra,0xffffa
    80006b70:	180080e7          	jalr	384(ra) # 80000cec <release>
}
    80006b74:	60e2                	ld	ra,24(sp)
    80006b76:	6442                	ld	s0,16(sp)
    80006b78:	64a2                	ld	s1,8(sp)
    80006b7a:	6105                	addi	sp,sp,32
    80006b7c:	8082                	ret
      panic("virtio_disk_intr status");
    80006b7e:	00002517          	auipc	a0,0x2
    80006b82:	b9250513          	addi	a0,a0,-1134 # 80008710 <etext+0x710>
    80006b86:	ffffa097          	auipc	ra,0xffffa
    80006b8a:	9da080e7          	jalr	-1574(ra) # 80000560 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
