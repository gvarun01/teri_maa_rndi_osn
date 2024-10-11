
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	3c013103          	ld	sp,960(sp) # 8000b3c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	3d070713          	addi	a4,a4,976 # 8000b420 <timer_scratch>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd1d5f>
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
    80000190:	3d450513          	addi	a0,a0,980 # 80013560 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aa4080e7          	jalr	-1372(ra) # 80000c38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00013497          	auipc	s1,0x13
    800001a0:	3c448493          	addi	s1,s1,964 # 80013560 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00013917          	auipc	s2,0x13
    800001a8:	45490913          	addi	s2,s2,1108 # 800135f8 <cons+0x98>
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
    800001ec:	37870713          	addi	a4,a4,888 # 80013560 <cons>
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
    8000023a:	32a50513          	addi	a0,a0,810 # 80013560 <cons>
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
    80000268:	38f72a23          	sw	a5,916(a4) # 800135f8 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00013517          	auipc	a0,0x13
    8000027e:	2e650513          	addi	a0,a0,742 # 80013560 <cons>
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
    800002e6:	27e50513          	addi	a0,a0,638 # 80013560 <cons>
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
    80000314:	25050513          	addi	a0,a0,592 # 80013560 <cons>
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
    80000336:	22e70713          	addi	a4,a4,558 # 80013560 <cons>
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
    80000360:	20478793          	addi	a5,a5,516 # 80013560 <cons>
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
    8000038e:	26e7a783          	lw	a5,622(a5) # 800135f8 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00013717          	auipc	a4,0x13
    800003a4:	1c070713          	addi	a4,a4,448 # 80013560 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00013497          	auipc	s1,0x13
    800003b4:	1b048493          	addi	s1,s1,432 # 80013560 <cons>
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
    800003fa:	16a70713          	addi	a4,a4,362 # 80013560 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addiw	a5,a5,-1
    8000040c:	00013717          	auipc	a4,0x13
    80000410:	1ef72a23          	sw	a5,500(a4) # 80013600 <cons+0xa0>
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
    80000436:	12e78793          	addi	a5,a5,302 # 80013560 <cons>
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
    8000045a:	1ac7a323          	sw	a2,422(a5) # 800135fc <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00013517          	auipc	a0,0x13
    80000462:	19a50513          	addi	a0,a0,410 # 800135f8 <cons+0x98>
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
    80000484:	0e050513          	addi	a0,a0,224 # 80013560 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	720080e7          	jalr	1824(ra) # 80000ba8 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	0002b797          	auipc	a5,0x2b
    8000049c:	47078793          	addi	a5,a5,1136 # 8002b908 <devsw>
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
    80000570:	0a07aa23          	sw	zero,180(a5) # 80013620 <pr+0x18>
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
    800005a4:	e4f72023          	sw	a5,-448(a4) # 8000b3e0 <panicked>
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
    800005ce:	056d2d03          	lw	s10,86(s10) # 80013620 <pr+0x18>
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
    8000061e:	fee50513          	addi	a0,a0,-18 # 80013608 <pr>
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
    800007a4:	e6850513          	addi	a0,a0,-408 # 80013608 <pr>
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
    800007c0:	e4c48493          	addi	s1,s1,-436 # 80013608 <pr>
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
    8000082c:	e0050513          	addi	a0,a0,-512 # 80013628 <uart_tx_lock>
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
    80000858:	b8c7a783          	lw	a5,-1140(a5) # 8000b3e0 <panicked>
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
    80000892:	b5a7b783          	ld	a5,-1190(a5) # 8000b3e8 <uart_tx_r>
    80000896:	0000b717          	auipc	a4,0xb
    8000089a:	b5a73703          	ld	a4,-1190(a4) # 8000b3f0 <uart_tx_w>
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
    800008c0:	d6ca8a93          	addi	s5,s5,-660 # 80013628 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	0000b497          	auipc	s1,0xb
    800008c8:	b2448493          	addi	s1,s1,-1244 # 8000b3e8 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	0000b997          	auipc	s3,0xb
    800008d4:	b2098993          	addi	s3,s3,-1248 # 8000b3f0 <uart_tx_w>
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
    80000934:	cf850513          	addi	a0,a0,-776 # 80013628 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	300080e7          	jalr	768(ra) # 80000c38 <acquire>
  if(panicked){
    80000940:	0000b797          	auipc	a5,0xb
    80000944:	aa07a783          	lw	a5,-1376(a5) # 8000b3e0 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	0000b717          	auipc	a4,0xb
    8000094e:	aa673703          	ld	a4,-1370(a4) # 8000b3f0 <uart_tx_w>
    80000952:	0000b797          	auipc	a5,0xb
    80000956:	a967b783          	ld	a5,-1386(a5) # 8000b3e8 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00013997          	auipc	s3,0x13
    80000962:	cca98993          	addi	s3,s3,-822 # 80013628 <uart_tx_lock>
    80000966:	0000b497          	auipc	s1,0xb
    8000096a:	a8248493          	addi	s1,s1,-1406 # 8000b3e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	0000b917          	auipc	s2,0xb
    80000972:	a8290913          	addi	s2,s2,-1406 # 8000b3f0 <uart_tx_w>
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
    80000998:	c9448493          	addi	s1,s1,-876 # 80013628 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	0000b797          	auipc	a5,0xb
    800009ac:	a4e7b423          	sd	a4,-1464(a5) # 8000b3f0 <uart_tx_w>
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
    80000a20:	c0c48493          	addi	s1,s1,-1012 # 80013628 <uart_tx_lock>
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
    80000a62:	04278793          	addi	a5,a5,66 # 8002caa0 <end>
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
    80000a82:	be290913          	addi	s2,s2,-1054 # 80013660 <kmem>
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
    80000b20:	b4450513          	addi	a0,a0,-1212 # 80013660 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	084080e7          	jalr	132(ra) # 80000ba8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	slli	a1,a1,0x1b
    80000b30:	0002c517          	auipc	a0,0x2c
    80000b34:	f7050513          	addi	a0,a0,-144 # 8002caa0 <end>
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
    80000b56:	b0e48493          	addi	s1,s1,-1266 # 80013660 <kmem>
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
    80000b6e:	af650513          	addi	a0,a0,-1290 # 80013660 <kmem>
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
    80000b9a:	aca50513          	addi	a0,a0,-1334 # 80013660 <kmem>
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
    80000da8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd2561>
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
    80000ee6:	51670713          	addi	a4,a4,1302 # 8000b3f8 <started>
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
    80000fb4:	684080e7          	jalr	1668(ra) # 80003634 <binit>
    iinit();         // inode table
    80000fb8:	00003097          	auipc	ra,0x3
    80000fbc:	d3a080e7          	jalr	-710(ra) # 80003cf2 <iinit>
    fileinit();      // file table
    80000fc0:	00004097          	auipc	ra,0x4
    80000fc4:	cea080e7          	jalr	-790(ra) # 80004caa <fileinit>
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
    80000fe2:	40f72d23          	sw	a5,1050(a4) # 8000b3f8 <started>
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
    80000ff6:	40e7b783          	ld	a5,1038(a5) # 8000b400 <kernel_pagetable>
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
    80001070:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd2557>
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
    800012b2:	14a7b923          	sd	a0,338(a5) # 8000b400 <kernel_pagetable>
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
    8000188c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd2560>
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
    800018d2:	9f248493          	addi	s1,s1,-1550 # 800142c0 <proc>
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
    800018fe:	dc6a8a93          	addi	s5,s5,-570 # 800216c0 <tickslock>
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
    80001966:	a0670713          	addi	a4,a4,-1530 # 8000b368 <seed.2>
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
    800019aa:	cda50513          	addi	a0,a0,-806 # 80013680 <pid_lock>
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	1fa080e7          	jalr	506(ra) # 80000ba8 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019b6:	00007597          	auipc	a1,0x7
    800019ba:	81258593          	addi	a1,a1,-2030 # 800081c8 <etext+0x1c8>
    800019be:	00012517          	auipc	a0,0x12
    800019c2:	cda50513          	addi	a0,a0,-806 # 80013698 <wait_lock>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	1e2080e7          	jalr	482(ra) # 80000ba8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    800019ce:	00013497          	auipc	s1,0x13
    800019d2:	8f248493          	addi	s1,s1,-1806 # 800142c0 <proc>
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
    80001a06:	cbea0a13          	addi	s4,s4,-834 # 800216c0 <tickslock>
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
    80001a24:	2785                	addiw	a5,a5,1 # ffffffff80000001 <end+0xfffffffefffd3561>
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
    80001a6e:	c4650513          	addi	a0,a0,-954 # 800136b0 <cpus>
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
    80001a96:	bee70713          	addi	a4,a4,-1042 # 80013680 <pid_lock>
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
    80001ace:	8967a783          	lw	a5,-1898(a5) # 8000b360 <first.1>
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
    80001ae8:	8607ae23          	sw	zero,-1924(a5) # 8000b360 <first.1>
    fsinit(ROOTDEV);
    80001aec:	4505                	li	a0,1
    80001aee:	00002097          	auipc	ra,0x2
    80001af2:	184080e7          	jalr	388(ra) # 80003c72 <fsinit>
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
    80001b08:	b7c90913          	addi	s2,s2,-1156 # 80013680 <pid_lock>
    80001b0c:	854a                	mv	a0,s2
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	12a080e7          	jalr	298(ra) # 80000c38 <acquire>
  pid = nextpid;
    80001b16:	0000a797          	auipc	a5,0xa
    80001b1a:	85a78793          	addi	a5,a5,-1958 # 8000b370 <nextpid>
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
    80001cac:	61848493          	addi	s1,s1,1560 # 800142c0 <proc>
    80001cb0:	00020917          	auipc	s2,0x20
    80001cb4:	a1090913          	addi	s2,s2,-1520 # 800216c0 <tickslock>
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
    80001d42:	6d67a783          	lw	a5,1750(a5) # 8000b414 <ticks>
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
    80001dc6:	64a7b323          	sd	a0,1606(a5) # 8000b408 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001dca:	03400613          	li	a2,52
    80001dce:	00009597          	auipc	a1,0x9
    80001dd2:	5b258593          	addi	a1,a1,1458 # 8000b380 <initcode>
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
    80001e18:	8b0080e7          	jalr	-1872(ra) # 800046c4 <namei>
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
    80001f54:	dec080e7          	jalr	-532(ra) # 80004d3c <filedup>
    80001f58:	00a93023          	sd	a0,0(s2)
    80001f5c:	b7e5                	j	80001f44 <fork+0xa8>
  np->cwd = idup(p->cwd);
    80001f5e:	328ab503          	ld	a0,808(s5)
    80001f62:	00002097          	auipc	ra,0x2
    80001f66:	f56080e7          	jalr	-170(ra) # 80003eb8 <idup>
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
    80001f9a:	70248493          	addi	s1,s1,1794 # 80013698 <wait_lock>
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
    8000203a:	64a70713          	addi	a4,a4,1610 # 80013680 <pid_lock>
    8000203e:	9766                	add	a4,a4,s9
    80002040:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &selected_proc->context);
    80002044:	00011717          	auipc	a4,0x11
    80002048:	67470713          	addi	a4,a4,1652 # 800136b8 <cpus+0x8>
    8000204c:	9cba                	add	s9,s9,a4
    for (p = proc; p < &proc[NPROC]; p++)
    8000204e:	0001f917          	auipc	s2,0x1f
    80002052:	67290913          	addi	s2,s2,1650 # 800216c0 <tickslock>
          p->arrival_time = ticks;
    80002056:	00009a17          	auipc	s4,0x9
    8000205a:	3bea0a13          	addi	s4,s4,958 # 8000b414 <ticks>
    c->proc = selected_proc;
    8000205e:	079e                	slli	a5,a5,0x7
    80002060:	00011c17          	auipc	s8,0x11
    80002064:	620c0c13          	addi	s8,s8,1568 # 80013680 <pid_lock>
    80002068:	9c3e                	add	s8,s8,a5
    8000206a:	aa11                	j	8000217e <scheduler_mlfq+0x16c>
      for (p = proc; p < &proc[NPROC]; p++)
    8000206c:	00012497          	auipc	s1,0x12
    80002070:	25448493          	addi	s1,s1,596 # 800142c0 <proc>
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
    800020ae:	3607a323          	sw	zero,870(a5) # 8000b410 <boost_ticks>
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
    80002174:	2a070713          	addi	a4,a4,672 # 8000b410 <boost_ticks>
    80002178:	431c                	lw	a5,0(a4)
    8000217a:	2785                	addiw	a5,a5,1
    8000217c:	c31c                	sw	a5,0(a4)
    if (boost_ticks >= BOOST_INTERVAL)
    8000217e:	00009b97          	auipc	s7,0x9
    80002182:	292b8b93          	addi	s7,s7,658 # 8000b410 <boost_ticks>
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
    800021aa:	11a78793          	addi	a5,a5,282 # 800142c0 <proc>
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
    800021d0:	4b470713          	addi	a4,a4,1204 # 80013680 <pid_lock>
    800021d4:	9756                	add	a4,a4,s5
    800021d6:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800021da:	00011717          	auipc	a4,0x11
    800021de:	4de70713          	addi	a4,a4,1246 # 800136b8 <cpus+0x8>
    800021e2:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    800021e4:	498d                	li	s3,3
        p->state = RUNNING;
    800021e6:	4b11                	li	s6,4
        c->proc = p;
    800021e8:	079e                	slli	a5,a5,0x7
    800021ea:	00011a17          	auipc	s4,0x11
    800021ee:	496a0a13          	addi	s4,s4,1174 # 80013680 <pid_lock>
    800021f2:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021f4:	0001f917          	auipc	s2,0x1f
    800021f8:	4cc90913          	addi	s2,s2,1228 # 800216c0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002200:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002204:	10079073          	csrw	sstatus,a5
    80002208:	00012497          	auipc	s1,0x12
    8000220c:	0b848493          	addi	s1,s1,184 # 800142c0 <proc>
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
    80002274:	41070713          	addi	a4,a4,1040 # 80013680 <pid_lock>
    80002278:	9736                	add	a4,a4,a3
    8000227a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &selected_proc->context);
    8000227e:	00011717          	auipc	a4,0x11
    80002282:	43a70713          	addi	a4,a4,1082 # 800136b8 <cpus+0x8>
    80002286:	00e68c33          	add	s8,a3,a4
    total_tickets = 0;
    8000228a:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    8000228c:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	0001f917          	auipc	s2,0x1f
    80002292:	43290913          	addi	s2,s2,1074 # 800216c0 <tickslock>
        c->proc = selected_proc;
    80002296:	00011b17          	auipc	s6,0x11
    8000229a:	3eab0b13          	addi	s6,s6,1002 # 80013680 <pid_lock>
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
    800022e4:	fe048493          	addi	s1,s1,-32 # 800142c0 <proc>
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
    800022fe:	fc648493          	addi	s1,s1,-58 # 800142c0 <proc>
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
    80002340:	f84a0a13          	addi	s4,s4,-124 # 800142c0 <proc>
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
    800023fe:	28670713          	addi	a4,a4,646 # 80013680 <pid_lock>
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
    80002424:	26090913          	addi	s2,s2,608 # 80013680 <pid_lock>
    80002428:	2781                	sext.w	a5,a5
    8000242a:	079e                	slli	a5,a5,0x7
    8000242c:	97ca                	add	a5,a5,s2
    8000242e:	0ac7a983          	lw	s3,172(a5)
    80002432:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002434:	2781                	sext.w	a5,a5
    80002436:	079e                	slli	a5,a5,0x7
    80002438:	00011597          	auipc	a1,0x11
    8000243c:	28058593          	addi	a1,a1,640 # 800136b8 <cpus+0x8>
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
    80002560:	d6448493          	addi	s1,s1,-668 # 800142c0 <proc>
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
    8000256c:	15890913          	addi	s2,s2,344 # 800216c0 <tickslock>
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
    800025d4:	cf048493          	addi	s1,s1,-784 # 800142c0 <proc>
      pp->parent = initproc;
    800025d8:	00009a17          	auipc	s4,0x9
    800025dc:	e30a0a13          	addi	s4,s4,-464 # 8000b408 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e0:	0001f997          	auipc	s3,0x1f
    800025e4:	0e098993          	addi	s3,s3,224 # 800216c0 <tickslock>
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
    80002638:	dd47b783          	ld	a5,-556(a5) # 8000b408 <initproc>
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
    8000265c:	736080e7          	jalr	1846(ra) # 80004d8e <fileclose>
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
    80002674:	254080e7          	jalr	596(ra) # 800048c4 <begin_op>
  iput(p->cwd);
    80002678:	3289b503          	ld	a0,808(s3)
    8000267c:	00002097          	auipc	ra,0x2
    80002680:	a38080e7          	jalr	-1480(ra) # 800040b4 <iput>
  end_op();
    80002684:	00002097          	auipc	ra,0x2
    80002688:	2ba080e7          	jalr	698(ra) # 8000493e <end_op>
  p->cwd = 0;
    8000268c:	3209b423          	sd	zero,808(s3)
  acquire(&wait_lock);
    80002690:	00011497          	auipc	s1,0x11
    80002694:	00848493          	addi	s1,s1,8 # 80013698 <wait_lock>
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
    800026d0:	d487a783          	lw	a5,-696(a5) # 8000b414 <ticks>
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
    8000270e:	bb648493          	addi	s1,s1,-1098 # 800142c0 <proc>
    80002712:	0001f997          	auipc	s3,0x1f
    80002716:	fae98993          	addi	s3,s3,-82 # 800216c0 <tickslock>
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
    800027f2:	eaa50513          	addi	a0,a0,-342 # 80013698 <wait_lock>
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
    80002808:	ebc98993          	addi	s3,s3,-324 # 800216c0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000280c:	00011c17          	auipc	s8,0x11
    80002810:	e8cc0c13          	addi	s8,s8,-372 # 80013698 <wait_lock>
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
    8000286e:	e2e50513          	addi	a0,a0,-466 # 80013698 <wait_lock>
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
    800028a2:	dfa50513          	addi	a0,a0,-518 # 80013698 <wait_lock>
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
    800028fe:	9c648493          	addi	s1,s1,-1594 # 800142c0 <proc>
    80002902:	bf65                	j	800028ba <wait+0xf0>
      release(&wait_lock);
    80002904:	00011517          	auipc	a0,0x11
    80002908:	d9450513          	addi	a0,a0,-620 # 80013698 <wait_lock>
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
    800029f2:	c0248493          	addi	s1,s1,-1022 # 800145f0 <proc+0x330>
    800029f6:	0001f917          	auipc	s2,0x1f
    800029fa:	ffa90913          	addi	s2,s2,-6 # 800219f0 <bcache+0x318>
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
    80002aa8:	bf450513          	addi	a0,a0,-1036 # 80013698 <wait_lock>
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
    80002abe:	c0698993          	addi	s3,s3,-1018 # 800216c0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002ac2:	00011d17          	auipc	s10,0x11
    80002ac6:	bd6d0d13          	addi	s10,s10,-1066 # 80013698 <wait_lock>
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
    80002b1c:	b8050513          	addi	a0,a0,-1152 # 80013698 <wait_lock>
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
    80002b54:	b4850513          	addi	a0,a0,-1208 # 80013698 <wait_lock>
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
    80002baa:	71a48493          	addi	s1,s1,1818 # 800142c0 <proc>
    80002bae:	bf7d                	j	80002b6c <waitx+0xf4>
      release(&wait_lock);
    80002bb0:	00011517          	auipc	a0,0x11
    80002bb4:	ae850513          	addi	a0,a0,-1304 # 80013698 <wait_lock>
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
    80002bd6:	6ee48493          	addi	s1,s1,1774 # 800142c0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002bda:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002bdc:	0001f917          	auipc	s2,0x1f
    80002be0:	ae490913          	addi	s2,s2,-1308 # 800216c0 <tickslock>
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
    80002ca0:	a2450513          	addi	a0,a0,-1500 # 800216c0 <tickslock>
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
    80002d80:	94490913          	addi	s2,s2,-1724 # 800216c0 <tickslock>
    80002d84:	854a                	mv	a0,s2
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	eb2080e7          	jalr	-334(ra) # 80000c38 <acquire>
  ticks++;
    80002d8e:	00008497          	auipc	s1,0x8
    80002d92:	68648493          	addi	s1,s1,1670 # 8000b414 <ticks>
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
  if (which_dev == 2 && p->alarm_interval > 0)
    80002eb6:	4789                	li	a5,2
    80002eb8:	06f51963          	bne	a0,a5,80002f2a <usertrap+0xbc>
    80002ebc:	0e44a703          	lw	a4,228(s1)
    80002ec0:	00e05e63          	blez	a4,80002edc <usertrap+0x6e>
    p->ticks++;
    80002ec4:	0e04a783          	lw	a5,224(s1)
    80002ec8:	2785                	addiw	a5,a5,1
    80002eca:	0007869b          	sext.w	a3,a5
    80002ece:	0ef4a023          	sw	a5,224(s1)
    if (p->ticks >= p->alarm_interval && p->alarm_active == 0)
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
  if (which_dev == 2 && p->alarm_interval > 0)
    80002f8c:	bf79                	j	80002f2a <usertrap+0xbc>
      p->ticks = 0;        // Reset the tick count
    80002f8e:	0e04a023          	sw	zero,224(s1)
      p->alarm_active = 1; // Mark that handler is active to prevent re-entry
    80002f92:	4785                	li	a5,1
    80002f94:	20f4a823          	sw	a5,528(s1)
      memmove(&p->alarm_tf, p->trapframe, sizeof(struct trapframe));
    80002f98:	12000613          	li	a2,288
    80002f9c:	2304b583          	ld	a1,560(s1)
    80002fa0:	0f048513          	addi	a0,s1,240
    80002fa4:	ffffe097          	auipc	ra,0xffffe
    80002fa8:	dec080e7          	jalr	-532(ra) # 80000d90 <memmove>
      p->trapframe->epc = p->handler;
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
    80003246:	0a89a903          	lw	s2,168(s3)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000324a:	fff9071b          	addiw	a4,s2,-1
    8000324e:	47e5                	li	a5,25
    80003250:	02e7ec63          	bltu	a5,a4,80003288 <syscall+0x5e>
    80003254:	e052                	sd	s4,0(sp)
    80003256:	00391713          	slli	a4,s2,0x3
    8000325a:	00005797          	auipc	a5,0x5
    8000325e:	52e78793          	addi	a5,a5,1326 # 80008788 <syscalls>
    80003262:	97ba                	add	a5,a5,a4
    80003264:	639c                	ld	a5,0(a5)
    80003266:	c385                	beqz	a5,80003286 <syscall+0x5c>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003268:	9782                	jalr	a5
    8000326a:	06a9b823          	sd	a0,112(s3)
    if(num<26 && num>=0)
    8000326e:	47e5                	li	a5,25
    80003270:	0527e363          	bltu	a5,s2,800032b6 <syscall+0x8c>
    {
      p->syscall_count[num]++;
    80003274:	090a                	slli	s2,s2,0x2
    80003276:	9926                	add	s2,s2,s1
    80003278:	04092783          	lw	a5,64(s2)
    8000327c:	2785                	addiw	a5,a5,1
    8000327e:	04f92023          	sw	a5,64(s2)
    80003282:	6a02                	ld	s4,0(sp)
    80003284:	a015                	j	800032a8 <syscall+0x7e>
    80003286:	6a02                	ld	s4,0(sp)
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003288:	86ca                	mv	a3,s2
    8000328a:	33048613          	addi	a2,s1,816
    8000328e:	588c                	lw	a1,48(s1)
    80003290:	00005517          	auipc	a0,0x5
    80003294:	13850513          	addi	a0,a0,312 # 800083c8 <etext+0x3c8>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	312080e7          	jalr	786(ra) # 800005aa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032a0:	2304b783          	ld	a5,560(s1)
    800032a4:	577d                	li	a4,-1
    800032a6:	fbb8                	sd	a4,112(a5)
  }
}
    800032a8:	70a2                	ld	ra,40(sp)
    800032aa:	7402                	ld	s0,32(sp)
    800032ac:	64e2                	ld	s1,24(sp)
    800032ae:	6942                	ld	s2,16(sp)
    800032b0:	69a2                	ld	s3,8(sp)
    800032b2:	6145                	addi	sp,sp,48
    800032b4:	8082                	ret
    800032b6:	6a02                	ld	s4,0(sp)
    800032b8:	bfc5                	j	800032a8 <syscall+0x7e>

00000000800032ba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032ba:	1101                	addi	sp,sp,-32
    800032bc:	ec06                	sd	ra,24(sp)
    800032be:	e822                	sd	s0,16(sp)
    800032c0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800032c2:	fec40593          	addi	a1,s0,-20
    800032c6:	4501                	li	a0,0
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	eea080e7          	jalr	-278(ra) # 800031b2 <argint>
  exit(n);
    800032d0:	fec42503          	lw	a0,-20(s0)
    800032d4:	fffff097          	auipc	ra,0xfffff
    800032d8:	344080e7          	jalr	836(ra) # 80002618 <exit>
  return 0; // not reached
}
    800032dc:	4501                	li	a0,0
    800032de:	60e2                	ld	ra,24(sp)
    800032e0:	6442                	ld	s0,16(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret

00000000800032e6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032e6:	1141                	addi	sp,sp,-16
    800032e8:	e406                	sd	ra,8(sp)
    800032ea:	e022                	sd	s0,0(sp)
    800032ec:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	78c080e7          	jalr	1932(ra) # 80001a7a <myproc>
}
    800032f6:	5908                	lw	a0,48(a0)
    800032f8:	60a2                	ld	ra,8(sp)
    800032fa:	6402                	ld	s0,0(sp)
    800032fc:	0141                	addi	sp,sp,16
    800032fe:	8082                	ret

0000000080003300 <sys_fork>:

uint64
sys_fork(void)
{
    80003300:	1141                	addi	sp,sp,-16
    80003302:	e406                	sd	ra,8(sp)
    80003304:	e022                	sd	s0,0(sp)
    80003306:	0800                	addi	s0,sp,16
  return fork();
    80003308:	fffff097          	auipc	ra,0xfffff
    8000330c:	b94080e7          	jalr	-1132(ra) # 80001e9c <fork>
}
    80003310:	60a2                	ld	ra,8(sp)
    80003312:	6402                	ld	s0,0(sp)
    80003314:	0141                	addi	sp,sp,16
    80003316:	8082                	ret

0000000080003318 <sys_wait>:

uint64
sys_wait(void)
{
    80003318:	1101                	addi	sp,sp,-32
    8000331a:	ec06                	sd	ra,24(sp)
    8000331c:	e822                	sd	s0,16(sp)
    8000331e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003320:	fe840593          	addi	a1,s0,-24
    80003324:	4501                	li	a0,0
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	eac080e7          	jalr	-340(ra) # 800031d2 <argaddr>
  return wait(p);
    8000332e:	fe843503          	ld	a0,-24(s0)
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	498080e7          	jalr	1176(ra) # 800027ca <wait>
}
    8000333a:	60e2                	ld	ra,24(sp)
    8000333c:	6442                	ld	s0,16(sp)
    8000333e:	6105                	addi	sp,sp,32
    80003340:	8082                	ret

0000000080003342 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003342:	7179                	addi	sp,sp,-48
    80003344:	f406                	sd	ra,40(sp)
    80003346:	f022                	sd	s0,32(sp)
    80003348:	ec26                	sd	s1,24(sp)
    8000334a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000334c:	fdc40593          	addi	a1,s0,-36
    80003350:	4501                	li	a0,0
    80003352:	00000097          	auipc	ra,0x0
    80003356:	e60080e7          	jalr	-416(ra) # 800031b2 <argint>
  addr = myproc()->sz;
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	720080e7          	jalr	1824(ra) # 80001a7a <myproc>
    80003362:	22053483          	ld	s1,544(a0)
  if (growproc(n) < 0)
    80003366:	fdc42503          	lw	a0,-36(s0)
    8000336a:	fffff097          	auipc	ra,0xfffff
    8000336e:	ace080e7          	jalr	-1330(ra) # 80001e38 <growproc>
    80003372:	00054863          	bltz	a0,80003382 <sys_sbrk+0x40>
    return -1;
  return addr;
}
    80003376:	8526                	mv	a0,s1
    80003378:	70a2                	ld	ra,40(sp)
    8000337a:	7402                	ld	s0,32(sp)
    8000337c:	64e2                	ld	s1,24(sp)
    8000337e:	6145                	addi	sp,sp,48
    80003380:	8082                	ret
    return -1;
    80003382:	54fd                	li	s1,-1
    80003384:	bfcd                	j	80003376 <sys_sbrk+0x34>

0000000080003386 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003386:	7139                	addi	sp,sp,-64
    80003388:	fc06                	sd	ra,56(sp)
    8000338a:	f822                	sd	s0,48(sp)
    8000338c:	f04a                	sd	s2,32(sp)
    8000338e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003390:	fcc40593          	addi	a1,s0,-52
    80003394:	4501                	li	a0,0
    80003396:	00000097          	auipc	ra,0x0
    8000339a:	e1c080e7          	jalr	-484(ra) # 800031b2 <argint>
  acquire(&tickslock);
    8000339e:	0001e517          	auipc	a0,0x1e
    800033a2:	32250513          	addi	a0,a0,802 # 800216c0 <tickslock>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	892080e7          	jalr	-1902(ra) # 80000c38 <acquire>
  ticks0 = ticks;
    800033ae:	00008917          	auipc	s2,0x8
    800033b2:	06692903          	lw	s2,102(s2) # 8000b414 <ticks>
  while (ticks - ticks0 < n)
    800033b6:	fcc42783          	lw	a5,-52(s0)
    800033ba:	c3b9                	beqz	a5,80003400 <sys_sleep+0x7a>
    800033bc:	f426                	sd	s1,40(sp)
    800033be:	ec4e                	sd	s3,24(sp)
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033c0:	0001e997          	auipc	s3,0x1e
    800033c4:	30098993          	addi	s3,s3,768 # 800216c0 <tickslock>
    800033c8:	00008497          	auipc	s1,0x8
    800033cc:	04c48493          	addi	s1,s1,76 # 8000b414 <ticks>
    if (killed(myproc()))
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	6aa080e7          	jalr	1706(ra) # 80001a7a <myproc>
    800033d8:	fffff097          	auipc	ra,0xfffff
    800033dc:	3c0080e7          	jalr	960(ra) # 80002798 <killed>
    800033e0:	ed15                	bnez	a0,8000341c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800033e2:	85ce                	mv	a1,s3
    800033e4:	8526                	mv	a0,s1
    800033e6:	fffff097          	auipc	ra,0xfffff
    800033ea:	0fe080e7          	jalr	254(ra) # 800024e4 <sleep>
  while (ticks - ticks0 < n)
    800033ee:	409c                	lw	a5,0(s1)
    800033f0:	412787bb          	subw	a5,a5,s2
    800033f4:	fcc42703          	lw	a4,-52(s0)
    800033f8:	fce7ece3          	bltu	a5,a4,800033d0 <sys_sleep+0x4a>
    800033fc:	74a2                	ld	s1,40(sp)
    800033fe:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80003400:	0001e517          	auipc	a0,0x1e
    80003404:	2c050513          	addi	a0,a0,704 # 800216c0 <tickslock>
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	8e4080e7          	jalr	-1820(ra) # 80000cec <release>
  return 0;
    80003410:	4501                	li	a0,0
}
    80003412:	70e2                	ld	ra,56(sp)
    80003414:	7442                	ld	s0,48(sp)
    80003416:	7902                	ld	s2,32(sp)
    80003418:	6121                	addi	sp,sp,64
    8000341a:	8082                	ret
      release(&tickslock);
    8000341c:	0001e517          	auipc	a0,0x1e
    80003420:	2a450513          	addi	a0,a0,676 # 800216c0 <tickslock>
    80003424:	ffffe097          	auipc	ra,0xffffe
    80003428:	8c8080e7          	jalr	-1848(ra) # 80000cec <release>
      return -1;
    8000342c:	557d                	li	a0,-1
    8000342e:	74a2                	ld	s1,40(sp)
    80003430:	69e2                	ld	s3,24(sp)
    80003432:	b7c5                	j	80003412 <sys_sleep+0x8c>

0000000080003434 <sys_kill>:

uint64
sys_kill(void)
{
    80003434:	1101                	addi	sp,sp,-32
    80003436:	ec06                	sd	ra,24(sp)
    80003438:	e822                	sd	s0,16(sp)
    8000343a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000343c:	fec40593          	addi	a1,s0,-20
    80003440:	4501                	li	a0,0
    80003442:	00000097          	auipc	ra,0x0
    80003446:	d70080e7          	jalr	-656(ra) # 800031b2 <argint>
  return kill(pid);
    8000344a:	fec42503          	lw	a0,-20(s0)
    8000344e:	fffff097          	auipc	ra,0xfffff
    80003452:	2ac080e7          	jalr	684(ra) # 800026fa <kill>
}
    80003456:	60e2                	ld	ra,24(sp)
    80003458:	6442                	ld	s0,16(sp)
    8000345a:	6105                	addi	sp,sp,32
    8000345c:	8082                	ret

000000008000345e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000345e:	1101                	addi	sp,sp,-32
    80003460:	ec06                	sd	ra,24(sp)
    80003462:	e822                	sd	s0,16(sp)
    80003464:	e426                	sd	s1,8(sp)
    80003466:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003468:	0001e517          	auipc	a0,0x1e
    8000346c:	25850513          	addi	a0,a0,600 # 800216c0 <tickslock>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	7c8080e7          	jalr	1992(ra) # 80000c38 <acquire>
  xticks = ticks;
    80003478:	00008497          	auipc	s1,0x8
    8000347c:	f9c4a483          	lw	s1,-100(s1) # 8000b414 <ticks>
  release(&tickslock);
    80003480:	0001e517          	auipc	a0,0x1e
    80003484:	24050513          	addi	a0,a0,576 # 800216c0 <tickslock>
    80003488:	ffffe097          	auipc	ra,0xffffe
    8000348c:	864080e7          	jalr	-1948(ra) # 80000cec <release>
  return xticks;
}
    80003490:	02049513          	slli	a0,s1,0x20
    80003494:	9101                	srli	a0,a0,0x20
    80003496:	60e2                	ld	ra,24(sp)
    80003498:	6442                	ld	s0,16(sp)
    8000349a:	64a2                	ld	s1,8(sp)
    8000349c:	6105                	addi	sp,sp,32
    8000349e:	8082                	ret

00000000800034a0 <sys_waitx>:

uint64
sys_waitx(void)
{
    800034a0:	7139                	addi	sp,sp,-64
    800034a2:	fc06                	sd	ra,56(sp)
    800034a4:	f822                	sd	s0,48(sp)
    800034a6:	f426                	sd	s1,40(sp)
    800034a8:	f04a                	sd	s2,32(sp)
    800034aa:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800034ac:	fd840593          	addi	a1,s0,-40
    800034b0:	4501                	li	a0,0
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	d20080e7          	jalr	-736(ra) # 800031d2 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800034ba:	fd040593          	addi	a1,s0,-48
    800034be:	4505                	li	a0,1
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	d12080e7          	jalr	-750(ra) # 800031d2 <argaddr>
  argaddr(2, &addr2);
    800034c8:	fc840593          	addi	a1,s0,-56
    800034cc:	4509                	li	a0,2
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	d04080e7          	jalr	-764(ra) # 800031d2 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800034d6:	fc040613          	addi	a2,s0,-64
    800034da:	fc440593          	addi	a1,s0,-60
    800034de:	fd843503          	ld	a0,-40(s0)
    800034e2:	fffff097          	auipc	ra,0xfffff
    800034e6:	596080e7          	jalr	1430(ra) # 80002a78 <waitx>
    800034ea:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800034ec:	ffffe097          	auipc	ra,0xffffe
    800034f0:	58e080e7          	jalr	1422(ra) # 80001a7a <myproc>
    800034f4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800034f6:	4691                	li	a3,4
    800034f8:	fc440613          	addi	a2,s0,-60
    800034fc:	fd043583          	ld	a1,-48(s0)
    80003500:	22853503          	ld	a0,552(a0)
    80003504:	ffffe097          	auipc	ra,0xffffe
    80003508:	1de080e7          	jalr	478(ra) # 800016e2 <copyout>
    return -1;
    8000350c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000350e:	02054063          	bltz	a0,8000352e <sys_waitx+0x8e>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003512:	4691                	li	a3,4
    80003514:	fc040613          	addi	a2,s0,-64
    80003518:	fc843583          	ld	a1,-56(s0)
    8000351c:	2284b503          	ld	a0,552(s1)
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	1c2080e7          	jalr	450(ra) # 800016e2 <copyout>
    80003528:	00054a63          	bltz	a0,8000353c <sys_waitx+0x9c>
    return -1;
  return ret;
    8000352c:	87ca                	mv	a5,s2
}
    8000352e:	853e                	mv	a0,a5
    80003530:	70e2                	ld	ra,56(sp)
    80003532:	7442                	ld	s0,48(sp)
    80003534:	74a2                	ld	s1,40(sp)
    80003536:	7902                	ld	s2,32(sp)
    80003538:	6121                	addi	sp,sp,64
    8000353a:	8082                	ret
    return -1;
    8000353c:	57fd                	li	a5,-1
    8000353e:	bfc5                	j	8000352e <sys_waitx+0x8e>

0000000080003540 <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    80003540:	1101                	addi	sp,sp,-32
    80003542:	ec06                	sd	ra,24(sp)
    80003544:	e822                	sd	s0,16(sp)
    80003546:	1000                	addi	s0,sp,32
  int k;
  argint(0, &k);
    80003548:	fec40593          	addi	a1,s0,-20
    8000354c:	4501                	li	a0,0
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	c64080e7          	jalr	-924(ra) # 800031b2 <argint>
  struct proc *p = myproc();
    80003556:	ffffe097          	auipc	ra,0xffffe
    8000355a:	524080e7          	jalr	1316(ra) # 80001a7a <myproc>
  return p->syscall_count[k];
    8000355e:	fec42783          	lw	a5,-20(s0)
    80003562:	07c1                	addi	a5,a5,16
    80003564:	078a                	slli	a5,a5,0x2
    80003566:	953e                	add	a0,a0,a5
}
    80003568:	4108                	lw	a0,0(a0)
    8000356a:	60e2                	ld	ra,24(sp)
    8000356c:	6442                	ld	s0,16(sp)
    8000356e:	6105                	addi	sp,sp,32
    80003570:	8082                	ret

0000000080003572 <sys_sigalarm>:

// In sysproc.c
uint64 sys_sigalarm(void)
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	1000                	addi	s0,sp,32
  int interval;
  uint64 handler;
  argaddr(1, &handler);
    8000357a:	fe040593          	addi	a1,s0,-32
    8000357e:	4505                	li	a0,1
    80003580:	00000097          	auipc	ra,0x0
    80003584:	c52080e7          	jalr	-942(ra) # 800031d2 <argaddr>
  argint(0, &interval);
    80003588:	fec40593          	addi	a1,s0,-20
    8000358c:	4501                	li	a0,0
    8000358e:	00000097          	auipc	ra,0x0
    80003592:	c24080e7          	jalr	-988(ra) # 800031b2 <argint>

  struct proc *p = myproc();
    80003596:	ffffe097          	auipc	ra,0xffffe
    8000359a:	4e4080e7          	jalr	1252(ra) # 80001a7a <myproc>
  p->alarm_interval = interval;
    8000359e:	fec42783          	lw	a5,-20(s0)
    800035a2:	0ef52223          	sw	a5,228(a0)
  p->handler = handler;
    800035a6:	fe043783          	ld	a5,-32(s0)
    800035aa:	f57c                	sd	a5,232(a0)
  p->ticks = 0;
    800035ac:	0e052023          	sw	zero,224(a0)
  p->alarm_active = 0; // Reset ticks
    800035b0:	20052823          	sw	zero,528(a0)

  return 0; // Success
}
    800035b4:	4501                	li	a0,0
    800035b6:	60e2                	ld	ra,24(sp)
    800035b8:	6442                	ld	s0,16(sp)
    800035ba:	6105                	addi	sp,sp,32
    800035bc:	8082                	ret

00000000800035be <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    800035be:	1101                	addi	sp,sp,-32
    800035c0:	ec06                	sd	ra,24(sp)
    800035c2:	e822                	sd	s0,16(sp)
    800035c4:	e426                	sd	s1,8(sp)
    800035c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800035c8:	ffffe097          	auipc	ra,0xffffe
    800035cc:	4b2080e7          	jalr	1202(ra) # 80001a7a <myproc>
    800035d0:	84aa                	mv	s1,a0
  memmove(p->trapframe, &p->alarm_tf, sizeof(struct trapframe)); // Restore context
    800035d2:	12000613          	li	a2,288
    800035d6:	0f050593          	addi	a1,a0,240
    800035da:	23053503          	ld	a0,560(a0)
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	7b2080e7          	jalr	1970(ra) # 80000d90 <memmove>
  p->alarm_active = 0;                                           // Allow future alarms
    800035e6:	2004a823          	sw	zero,528(s1)
  uint64 return_value = p->trapframe->a0;
    800035ea:	2304b783          	ld	a5,560(s1)
  return return_value;
}
    800035ee:	7ba8                	ld	a0,112(a5)
    800035f0:	60e2                	ld	ra,24(sp)
    800035f2:	6442                	ld	s0,16(sp)
    800035f4:	64a2                	ld	s1,8(sp)
    800035f6:	6105                	addi	sp,sp,32
    800035f8:	8082                	ret

00000000800035fa <sys_settickets>:

uint64
sys_settickets(void)
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	1000                	addi	s0,sp,32
  int number;
  argint(0, &number);
    80003602:	fec40593          	addi	a1,s0,-20
    80003606:	4501                	li	a0,0
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	baa080e7          	jalr	-1110(ra) # 800031b2 <argint>
  if (number < 1)
    80003610:	fec42783          	lw	a5,-20(s0)
    return -1;
    80003614:	557d                	li	a0,-1
  if (number < 1)
    80003616:	00f05b63          	blez	a5,8000362c <sys_settickets+0x32>
  struct proc *p = myproc();
    8000361a:	ffffe097          	auipc	ra,0xffffe
    8000361e:	460080e7          	jalr	1120(ra) # 80001a7a <myproc>
  p->tickets = number;
    80003622:	fec42783          	lw	a5,-20(s0)
    80003626:	0cf52023          	sw	a5,192(a0)
  return 0;
    8000362a:	4501                	li	a0,0
    8000362c:	60e2                	ld	ra,24(sp)
    8000362e:	6442                	ld	s0,16(sp)
    80003630:	6105                	addi	sp,sp,32
    80003632:	8082                	ret

0000000080003634 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	e052                	sd	s4,0(sp)
    80003642:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003644:	00005597          	auipc	a1,0x5
    80003648:	da458593          	addi	a1,a1,-604 # 800083e8 <etext+0x3e8>
    8000364c:	0001e517          	auipc	a0,0x1e
    80003650:	08c50513          	addi	a0,a0,140 # 800216d8 <bcache>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	554080e7          	jalr	1364(ra) # 80000ba8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000365c:	00026797          	auipc	a5,0x26
    80003660:	07c78793          	addi	a5,a5,124 # 800296d8 <bcache+0x8000>
    80003664:	00026717          	auipc	a4,0x26
    80003668:	2dc70713          	addi	a4,a4,732 # 80029940 <bcache+0x8268>
    8000366c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003670:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003674:	0001e497          	auipc	s1,0x1e
    80003678:	07c48493          	addi	s1,s1,124 # 800216f0 <bcache+0x18>
    b->next = bcache.head.next;
    8000367c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000367e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003680:	00005a17          	auipc	s4,0x5
    80003684:	d70a0a13          	addi	s4,s4,-656 # 800083f0 <etext+0x3f0>
    b->next = bcache.head.next;
    80003688:	2b893783          	ld	a5,696(s2)
    8000368c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000368e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003692:	85d2                	mv	a1,s4
    80003694:	01048513          	addi	a0,s1,16
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	4e8080e7          	jalr	1256(ra) # 80004b80 <initsleeplock>
    bcache.head.next->prev = b;
    800036a0:	2b893783          	ld	a5,696(s2)
    800036a4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036a6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036aa:	45848493          	addi	s1,s1,1112
    800036ae:	fd349de3          	bne	s1,s3,80003688 <binit+0x54>
  }
}
    800036b2:	70a2                	ld	ra,40(sp)
    800036b4:	7402                	ld	s0,32(sp)
    800036b6:	64e2                	ld	s1,24(sp)
    800036b8:	6942                	ld	s2,16(sp)
    800036ba:	69a2                	ld	s3,8(sp)
    800036bc:	6a02                	ld	s4,0(sp)
    800036be:	6145                	addi	sp,sp,48
    800036c0:	8082                	ret

00000000800036c2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036c2:	7179                	addi	sp,sp,-48
    800036c4:	f406                	sd	ra,40(sp)
    800036c6:	f022                	sd	s0,32(sp)
    800036c8:	ec26                	sd	s1,24(sp)
    800036ca:	e84a                	sd	s2,16(sp)
    800036cc:	e44e                	sd	s3,8(sp)
    800036ce:	1800                	addi	s0,sp,48
    800036d0:	892a                	mv	s2,a0
    800036d2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036d4:	0001e517          	auipc	a0,0x1e
    800036d8:	00450513          	addi	a0,a0,4 # 800216d8 <bcache>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	55c080e7          	jalr	1372(ra) # 80000c38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036e4:	00026497          	auipc	s1,0x26
    800036e8:	2ac4b483          	ld	s1,684(s1) # 80029990 <bcache+0x82b8>
    800036ec:	00026797          	auipc	a5,0x26
    800036f0:	25478793          	addi	a5,a5,596 # 80029940 <bcache+0x8268>
    800036f4:	02f48f63          	beq	s1,a5,80003732 <bread+0x70>
    800036f8:	873e                	mv	a4,a5
    800036fa:	a021                	j	80003702 <bread+0x40>
    800036fc:	68a4                	ld	s1,80(s1)
    800036fe:	02e48a63          	beq	s1,a4,80003732 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003702:	449c                	lw	a5,8(s1)
    80003704:	ff279ce3          	bne	a5,s2,800036fc <bread+0x3a>
    80003708:	44dc                	lw	a5,12(s1)
    8000370a:	ff3799e3          	bne	a5,s3,800036fc <bread+0x3a>
      b->refcnt++;
    8000370e:	40bc                	lw	a5,64(s1)
    80003710:	2785                	addiw	a5,a5,1
    80003712:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003714:	0001e517          	auipc	a0,0x1e
    80003718:	fc450513          	addi	a0,a0,-60 # 800216d8 <bcache>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	5d0080e7          	jalr	1488(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    80003724:	01048513          	addi	a0,s1,16
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	492080e7          	jalr	1170(ra) # 80004bba <acquiresleep>
      return b;
    80003730:	a8b9                	j	8000378e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003732:	00026497          	auipc	s1,0x26
    80003736:	2564b483          	ld	s1,598(s1) # 80029988 <bcache+0x82b0>
    8000373a:	00026797          	auipc	a5,0x26
    8000373e:	20678793          	addi	a5,a5,518 # 80029940 <bcache+0x8268>
    80003742:	00f48863          	beq	s1,a5,80003752 <bread+0x90>
    80003746:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003748:	40bc                	lw	a5,64(s1)
    8000374a:	cf81                	beqz	a5,80003762 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000374c:	64a4                	ld	s1,72(s1)
    8000374e:	fee49de3          	bne	s1,a4,80003748 <bread+0x86>
  panic("bget: no buffers");
    80003752:	00005517          	auipc	a0,0x5
    80003756:	ca650513          	addi	a0,a0,-858 # 800083f8 <etext+0x3f8>
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	e06080e7          	jalr	-506(ra) # 80000560 <panic>
      b->dev = dev;
    80003762:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003766:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000376a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000376e:	4785                	li	a5,1
    80003770:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003772:	0001e517          	auipc	a0,0x1e
    80003776:	f6650513          	addi	a0,a0,-154 # 800216d8 <bcache>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	572080e7          	jalr	1394(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    80003782:	01048513          	addi	a0,s1,16
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	434080e7          	jalr	1076(ra) # 80004bba <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000378e:	409c                	lw	a5,0(s1)
    80003790:	cb89                	beqz	a5,800037a2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003792:	8526                	mv	a0,s1
    80003794:	70a2                	ld	ra,40(sp)
    80003796:	7402                	ld	s0,32(sp)
    80003798:	64e2                	ld	s1,24(sp)
    8000379a:	6942                	ld	s2,16(sp)
    8000379c:	69a2                	ld	s3,8(sp)
    8000379e:	6145                	addi	sp,sp,48
    800037a0:	8082                	ret
    virtio_disk_rw(b, 0);
    800037a2:	4581                	li	a1,0
    800037a4:	8526                	mv	a0,s1
    800037a6:	00003097          	auipc	ra,0x3
    800037aa:	102080e7          	jalr	258(ra) # 800068a8 <virtio_disk_rw>
    b->valid = 1;
    800037ae:	4785                	li	a5,1
    800037b0:	c09c                	sw	a5,0(s1)
  return b;
    800037b2:	b7c5                	j	80003792 <bread+0xd0>

00000000800037b4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	e426                	sd	s1,8(sp)
    800037bc:	1000                	addi	s0,sp,32
    800037be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037c0:	0541                	addi	a0,a0,16
    800037c2:	00001097          	auipc	ra,0x1
    800037c6:	492080e7          	jalr	1170(ra) # 80004c54 <holdingsleep>
    800037ca:	cd01                	beqz	a0,800037e2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037cc:	4585                	li	a1,1
    800037ce:	8526                	mv	a0,s1
    800037d0:	00003097          	auipc	ra,0x3
    800037d4:	0d8080e7          	jalr	216(ra) # 800068a8 <virtio_disk_rw>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret
    panic("bwrite");
    800037e2:	00005517          	auipc	a0,0x5
    800037e6:	c2e50513          	addi	a0,a0,-978 # 80008410 <etext+0x410>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	d76080e7          	jalr	-650(ra) # 80000560 <panic>

00000000800037f2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	e04a                	sd	s2,0(sp)
    800037fc:	1000                	addi	s0,sp,32
    800037fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003800:	01050913          	addi	s2,a0,16
    80003804:	854a                	mv	a0,s2
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	44e080e7          	jalr	1102(ra) # 80004c54 <holdingsleep>
    8000380e:	c925                	beqz	a0,8000387e <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	3fe080e7          	jalr	1022(ra) # 80004c10 <releasesleep>

  acquire(&bcache.lock);
    8000381a:	0001e517          	auipc	a0,0x1e
    8000381e:	ebe50513          	addi	a0,a0,-322 # 800216d8 <bcache>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	416080e7          	jalr	1046(ra) # 80000c38 <acquire>
  b->refcnt--;
    8000382a:	40bc                	lw	a5,64(s1)
    8000382c:	37fd                	addiw	a5,a5,-1
    8000382e:	0007871b          	sext.w	a4,a5
    80003832:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003834:	e71d                	bnez	a4,80003862 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003836:	68b8                	ld	a4,80(s1)
    80003838:	64bc                	ld	a5,72(s1)
    8000383a:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    8000383c:	68b8                	ld	a4,80(s1)
    8000383e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003840:	00026797          	auipc	a5,0x26
    80003844:	e9878793          	addi	a5,a5,-360 # 800296d8 <bcache+0x8000>
    80003848:	2b87b703          	ld	a4,696(a5)
    8000384c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000384e:	00026717          	auipc	a4,0x26
    80003852:	0f270713          	addi	a4,a4,242 # 80029940 <bcache+0x8268>
    80003856:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003858:	2b87b703          	ld	a4,696(a5)
    8000385c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000385e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003862:	0001e517          	auipc	a0,0x1e
    80003866:	e7650513          	addi	a0,a0,-394 # 800216d8 <bcache>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	482080e7          	jalr	1154(ra) # 80000cec <release>
}
    80003872:	60e2                	ld	ra,24(sp)
    80003874:	6442                	ld	s0,16(sp)
    80003876:	64a2                	ld	s1,8(sp)
    80003878:	6902                	ld	s2,0(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret
    panic("brelse");
    8000387e:	00005517          	auipc	a0,0x5
    80003882:	b9a50513          	addi	a0,a0,-1126 # 80008418 <etext+0x418>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	cda080e7          	jalr	-806(ra) # 80000560 <panic>

000000008000388e <bpin>:

void
bpin(struct buf *b) {
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	1000                	addi	s0,sp,32
    80003898:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000389a:	0001e517          	auipc	a0,0x1e
    8000389e:	e3e50513          	addi	a0,a0,-450 # 800216d8 <bcache>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	396080e7          	jalr	918(ra) # 80000c38 <acquire>
  b->refcnt++;
    800038aa:	40bc                	lw	a5,64(s1)
    800038ac:	2785                	addiw	a5,a5,1
    800038ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038b0:	0001e517          	auipc	a0,0x1e
    800038b4:	e2850513          	addi	a0,a0,-472 # 800216d8 <bcache>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	434080e7          	jalr	1076(ra) # 80000cec <release>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret

00000000800038ca <bunpin>:

void
bunpin(struct buf *b) {
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	1000                	addi	s0,sp,32
    800038d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d6:	0001e517          	auipc	a0,0x1e
    800038da:	e0250513          	addi	a0,a0,-510 # 800216d8 <bcache>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	35a080e7          	jalr	858(ra) # 80000c38 <acquire>
  b->refcnt--;
    800038e6:	40bc                	lw	a5,64(s1)
    800038e8:	37fd                	addiw	a5,a5,-1
    800038ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ec:	0001e517          	auipc	a0,0x1e
    800038f0:	dec50513          	addi	a0,a0,-532 # 800216d8 <bcache>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	3f8080e7          	jalr	1016(ra) # 80000cec <release>
}
    800038fc:	60e2                	ld	ra,24(sp)
    800038fe:	6442                	ld	s0,16(sp)
    80003900:	64a2                	ld	s1,8(sp)
    80003902:	6105                	addi	sp,sp,32
    80003904:	8082                	ret

0000000080003906 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003906:	1101                	addi	sp,sp,-32
    80003908:	ec06                	sd	ra,24(sp)
    8000390a:	e822                	sd	s0,16(sp)
    8000390c:	e426                	sd	s1,8(sp)
    8000390e:	e04a                	sd	s2,0(sp)
    80003910:	1000                	addi	s0,sp,32
    80003912:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003914:	00d5d59b          	srliw	a1,a1,0xd
    80003918:	00026797          	auipc	a5,0x26
    8000391c:	49c7a783          	lw	a5,1180(a5) # 80029db4 <sb+0x1c>
    80003920:	9dbd                	addw	a1,a1,a5
    80003922:	00000097          	auipc	ra,0x0
    80003926:	da0080e7          	jalr	-608(ra) # 800036c2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000392a:	0074f713          	andi	a4,s1,7
    8000392e:	4785                	li	a5,1
    80003930:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003934:	14ce                	slli	s1,s1,0x33
    80003936:	90d9                	srli	s1,s1,0x36
    80003938:	00950733          	add	a4,a0,s1
    8000393c:	05874703          	lbu	a4,88(a4)
    80003940:	00e7f6b3          	and	a3,a5,a4
    80003944:	c69d                	beqz	a3,80003972 <bfree+0x6c>
    80003946:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003948:	94aa                	add	s1,s1,a0
    8000394a:	fff7c793          	not	a5,a5
    8000394e:	8f7d                	and	a4,a4,a5
    80003950:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003954:	00001097          	auipc	ra,0x1
    80003958:	148080e7          	jalr	328(ra) # 80004a9c <log_write>
  brelse(bp);
    8000395c:	854a                	mv	a0,s2
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	e94080e7          	jalr	-364(ra) # 800037f2 <brelse>
}
    80003966:	60e2                	ld	ra,24(sp)
    80003968:	6442                	ld	s0,16(sp)
    8000396a:	64a2                	ld	s1,8(sp)
    8000396c:	6902                	ld	s2,0(sp)
    8000396e:	6105                	addi	sp,sp,32
    80003970:	8082                	ret
    panic("freeing free block");
    80003972:	00005517          	auipc	a0,0x5
    80003976:	aae50513          	addi	a0,a0,-1362 # 80008420 <etext+0x420>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	be6080e7          	jalr	-1050(ra) # 80000560 <panic>

0000000080003982 <balloc>:
{
    80003982:	711d                	addi	sp,sp,-96
    80003984:	ec86                	sd	ra,88(sp)
    80003986:	e8a2                	sd	s0,80(sp)
    80003988:	e4a6                	sd	s1,72(sp)
    8000398a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000398c:	00026797          	auipc	a5,0x26
    80003990:	4107a783          	lw	a5,1040(a5) # 80029d9c <sb+0x4>
    80003994:	10078f63          	beqz	a5,80003ab2 <balloc+0x130>
    80003998:	e0ca                	sd	s2,64(sp)
    8000399a:	fc4e                	sd	s3,56(sp)
    8000399c:	f852                	sd	s4,48(sp)
    8000399e:	f456                	sd	s5,40(sp)
    800039a0:	f05a                	sd	s6,32(sp)
    800039a2:	ec5e                	sd	s7,24(sp)
    800039a4:	e862                	sd	s8,16(sp)
    800039a6:	e466                	sd	s9,8(sp)
    800039a8:	8baa                	mv	s7,a0
    800039aa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039ac:	00026b17          	auipc	s6,0x26
    800039b0:	3ecb0b13          	addi	s6,s6,1004 # 80029d98 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039b6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039ba:	6c89                	lui	s9,0x2
    800039bc:	a061                	j	80003a44 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039be:	97ca                	add	a5,a5,s2
    800039c0:	8e55                	or	a2,a2,a3
    800039c2:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	0d4080e7          	jalr	212(ra) # 80004a9c <log_write>
        brelse(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	e20080e7          	jalr	-480(ra) # 800037f2 <brelse>
  bp = bread(dev, bno);
    800039da:	85a6                	mv	a1,s1
    800039dc:	855e                	mv	a0,s7
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	ce4080e7          	jalr	-796(ra) # 800036c2 <bread>
    800039e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039e8:	40000613          	li	a2,1024
    800039ec:	4581                	li	a1,0
    800039ee:	05850513          	addi	a0,a0,88
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	342080e7          	jalr	834(ra) # 80000d34 <memset>
  log_write(bp);
    800039fa:	854a                	mv	a0,s2
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	0a0080e7          	jalr	160(ra) # 80004a9c <log_write>
  brelse(bp);
    80003a04:	854a                	mv	a0,s2
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	dec080e7          	jalr	-532(ra) # 800037f2 <brelse>
}
    80003a0e:	6906                	ld	s2,64(sp)
    80003a10:	79e2                	ld	s3,56(sp)
    80003a12:	7a42                	ld	s4,48(sp)
    80003a14:	7aa2                	ld	s5,40(sp)
    80003a16:	7b02                	ld	s6,32(sp)
    80003a18:	6be2                	ld	s7,24(sp)
    80003a1a:	6c42                	ld	s8,16(sp)
    80003a1c:	6ca2                	ld	s9,8(sp)
}
    80003a1e:	8526                	mv	a0,s1
    80003a20:	60e6                	ld	ra,88(sp)
    80003a22:	6446                	ld	s0,80(sp)
    80003a24:	64a6                	ld	s1,72(sp)
    80003a26:	6125                	addi	sp,sp,96
    80003a28:	8082                	ret
    brelse(bp);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	dc6080e7          	jalr	-570(ra) # 800037f2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a34:	015c87bb          	addw	a5,s9,s5
    80003a38:	00078a9b          	sext.w	s5,a5
    80003a3c:	004b2703          	lw	a4,4(s6)
    80003a40:	06eaf163          	bgeu	s5,a4,80003aa2 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    80003a44:	41fad79b          	sraiw	a5,s5,0x1f
    80003a48:	0137d79b          	srliw	a5,a5,0x13
    80003a4c:	015787bb          	addw	a5,a5,s5
    80003a50:	40d7d79b          	sraiw	a5,a5,0xd
    80003a54:	01cb2583          	lw	a1,28(s6)
    80003a58:	9dbd                	addw	a1,a1,a5
    80003a5a:	855e                	mv	a0,s7
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	c66080e7          	jalr	-922(ra) # 800036c2 <bread>
    80003a64:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a66:	004b2503          	lw	a0,4(s6)
    80003a6a:	000a849b          	sext.w	s1,s5
    80003a6e:	8762                	mv	a4,s8
    80003a70:	faa4fde3          	bgeu	s1,a0,80003a2a <balloc+0xa8>
      m = 1 << (bi % 8);
    80003a74:	00777693          	andi	a3,a4,7
    80003a78:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a7c:	41f7579b          	sraiw	a5,a4,0x1f
    80003a80:	01d7d79b          	srliw	a5,a5,0x1d
    80003a84:	9fb9                	addw	a5,a5,a4
    80003a86:	4037d79b          	sraiw	a5,a5,0x3
    80003a8a:	00f90633          	add	a2,s2,a5
    80003a8e:	05864603          	lbu	a2,88(a2)
    80003a92:	00c6f5b3          	and	a1,a3,a2
    80003a96:	d585                	beqz	a1,800039be <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a98:	2705                	addiw	a4,a4,1
    80003a9a:	2485                	addiw	s1,s1,1
    80003a9c:	fd471ae3          	bne	a4,s4,80003a70 <balloc+0xee>
    80003aa0:	b769                	j	80003a2a <balloc+0xa8>
    80003aa2:	6906                	ld	s2,64(sp)
    80003aa4:	79e2                	ld	s3,56(sp)
    80003aa6:	7a42                	ld	s4,48(sp)
    80003aa8:	7aa2                	ld	s5,40(sp)
    80003aaa:	7b02                	ld	s6,32(sp)
    80003aac:	6be2                	ld	s7,24(sp)
    80003aae:	6c42                	ld	s8,16(sp)
    80003ab0:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003ab2:	00005517          	auipc	a0,0x5
    80003ab6:	98650513          	addi	a0,a0,-1658 # 80008438 <etext+0x438>
    80003aba:	ffffd097          	auipc	ra,0xffffd
    80003abe:	af0080e7          	jalr	-1296(ra) # 800005aa <printf>
  return 0;
    80003ac2:	4481                	li	s1,0
    80003ac4:	bfa9                	j	80003a1e <balloc+0x9c>

0000000080003ac6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ac6:	7179                	addi	sp,sp,-48
    80003ac8:	f406                	sd	ra,40(sp)
    80003aca:	f022                	sd	s0,32(sp)
    80003acc:	ec26                	sd	s1,24(sp)
    80003ace:	e84a                	sd	s2,16(sp)
    80003ad0:	e44e                	sd	s3,8(sp)
    80003ad2:	1800                	addi	s0,sp,48
    80003ad4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ad6:	47ad                	li	a5,11
    80003ad8:	02b7e863          	bltu	a5,a1,80003b08 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003adc:	02059793          	slli	a5,a1,0x20
    80003ae0:	01e7d593          	srli	a1,a5,0x1e
    80003ae4:	00b504b3          	add	s1,a0,a1
    80003ae8:	0504a903          	lw	s2,80(s1)
    80003aec:	08091263          	bnez	s2,80003b70 <bmap+0xaa>
      addr = balloc(ip->dev);
    80003af0:	4108                	lw	a0,0(a0)
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	e90080e7          	jalr	-368(ra) # 80003982 <balloc>
    80003afa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003afe:	06090963          	beqz	s2,80003b70 <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    80003b02:	0524a823          	sw	s2,80(s1)
    80003b06:	a0ad                	j	80003b70 <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003b08:	ff45849b          	addiw	s1,a1,-12
    80003b0c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b10:	0ff00793          	li	a5,255
    80003b14:	08e7e863          	bltu	a5,a4,80003ba4 <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b18:	08052903          	lw	s2,128(a0)
    80003b1c:	00091f63          	bnez	s2,80003b3a <bmap+0x74>
      addr = balloc(ip->dev);
    80003b20:	4108                	lw	a0,0(a0)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	e60080e7          	jalr	-416(ra) # 80003982 <balloc>
    80003b2a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b2e:	04090163          	beqz	s2,80003b70 <bmap+0xaa>
    80003b32:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b34:	0929a023          	sw	s2,128(s3)
    80003b38:	a011                	j	80003b3c <bmap+0x76>
    80003b3a:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003b3c:	85ca                	mv	a1,s2
    80003b3e:	0009a503          	lw	a0,0(s3)
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	b80080e7          	jalr	-1152(ra) # 800036c2 <bread>
    80003b4a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b4c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b50:	02049713          	slli	a4,s1,0x20
    80003b54:	01e75593          	srli	a1,a4,0x1e
    80003b58:	00b784b3          	add	s1,a5,a1
    80003b5c:	0004a903          	lw	s2,0(s1)
    80003b60:	02090063          	beqz	s2,80003b80 <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b64:	8552                	mv	a0,s4
    80003b66:	00000097          	auipc	ra,0x0
    80003b6a:	c8c080e7          	jalr	-884(ra) # 800037f2 <brelse>
    return addr;
    80003b6e:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003b70:	854a                	mv	a0,s2
    80003b72:	70a2                	ld	ra,40(sp)
    80003b74:	7402                	ld	s0,32(sp)
    80003b76:	64e2                	ld	s1,24(sp)
    80003b78:	6942                	ld	s2,16(sp)
    80003b7a:	69a2                	ld	s3,8(sp)
    80003b7c:	6145                	addi	sp,sp,48
    80003b7e:	8082                	ret
      addr = balloc(ip->dev);
    80003b80:	0009a503          	lw	a0,0(s3)
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	dfe080e7          	jalr	-514(ra) # 80003982 <balloc>
    80003b8c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b90:	fc090ae3          	beqz	s2,80003b64 <bmap+0x9e>
        a[bn] = addr;
    80003b94:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b98:	8552                	mv	a0,s4
    80003b9a:	00001097          	auipc	ra,0x1
    80003b9e:	f02080e7          	jalr	-254(ra) # 80004a9c <log_write>
    80003ba2:	b7c9                	j	80003b64 <bmap+0x9e>
    80003ba4:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	8aa50513          	addi	a0,a0,-1878 # 80008450 <etext+0x450>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	9b2080e7          	jalr	-1614(ra) # 80000560 <panic>

0000000080003bb6 <iget>:
{
    80003bb6:	7179                	addi	sp,sp,-48
    80003bb8:	f406                	sd	ra,40(sp)
    80003bba:	f022                	sd	s0,32(sp)
    80003bbc:	ec26                	sd	s1,24(sp)
    80003bbe:	e84a                	sd	s2,16(sp)
    80003bc0:	e44e                	sd	s3,8(sp)
    80003bc2:	e052                	sd	s4,0(sp)
    80003bc4:	1800                	addi	s0,sp,48
    80003bc6:	89aa                	mv	s3,a0
    80003bc8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bca:	00026517          	auipc	a0,0x26
    80003bce:	1ee50513          	addi	a0,a0,494 # 80029db8 <itable>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	066080e7          	jalr	102(ra) # 80000c38 <acquire>
  empty = 0;
    80003bda:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bdc:	00026497          	auipc	s1,0x26
    80003be0:	1f448493          	addi	s1,s1,500 # 80029dd0 <itable+0x18>
    80003be4:	00028697          	auipc	a3,0x28
    80003be8:	c7c68693          	addi	a3,a3,-900 # 8002b860 <log>
    80003bec:	a039                	j	80003bfa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bee:	02090b63          	beqz	s2,80003c24 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bf2:	08848493          	addi	s1,s1,136
    80003bf6:	02d48a63          	beq	s1,a3,80003c2a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bfa:	449c                	lw	a5,8(s1)
    80003bfc:	fef059e3          	blez	a5,80003bee <iget+0x38>
    80003c00:	4098                	lw	a4,0(s1)
    80003c02:	ff3716e3          	bne	a4,s3,80003bee <iget+0x38>
    80003c06:	40d8                	lw	a4,4(s1)
    80003c08:	ff4713e3          	bne	a4,s4,80003bee <iget+0x38>
      ip->ref++;
    80003c0c:	2785                	addiw	a5,a5,1
    80003c0e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c10:	00026517          	auipc	a0,0x26
    80003c14:	1a850513          	addi	a0,a0,424 # 80029db8 <itable>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	0d4080e7          	jalr	212(ra) # 80000cec <release>
      return ip;
    80003c20:	8926                	mv	s2,s1
    80003c22:	a03d                	j	80003c50 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c24:	f7f9                	bnez	a5,80003bf2 <iget+0x3c>
      empty = ip;
    80003c26:	8926                	mv	s2,s1
    80003c28:	b7e9                	j	80003bf2 <iget+0x3c>
  if(empty == 0)
    80003c2a:	02090c63          	beqz	s2,80003c62 <iget+0xac>
  ip->dev = dev;
    80003c2e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c32:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c36:	4785                	li	a5,1
    80003c38:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c3c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c40:	00026517          	auipc	a0,0x26
    80003c44:	17850513          	addi	a0,a0,376 # 80029db8 <itable>
    80003c48:	ffffd097          	auipc	ra,0xffffd
    80003c4c:	0a4080e7          	jalr	164(ra) # 80000cec <release>
}
    80003c50:	854a                	mv	a0,s2
    80003c52:	70a2                	ld	ra,40(sp)
    80003c54:	7402                	ld	s0,32(sp)
    80003c56:	64e2                	ld	s1,24(sp)
    80003c58:	6942                	ld	s2,16(sp)
    80003c5a:	69a2                	ld	s3,8(sp)
    80003c5c:	6a02                	ld	s4,0(sp)
    80003c5e:	6145                	addi	sp,sp,48
    80003c60:	8082                	ret
    panic("iget: no inodes");
    80003c62:	00005517          	auipc	a0,0x5
    80003c66:	80650513          	addi	a0,a0,-2042 # 80008468 <etext+0x468>
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	8f6080e7          	jalr	-1802(ra) # 80000560 <panic>

0000000080003c72 <fsinit>:
fsinit(int dev) {
    80003c72:	7179                	addi	sp,sp,-48
    80003c74:	f406                	sd	ra,40(sp)
    80003c76:	f022                	sd	s0,32(sp)
    80003c78:	ec26                	sd	s1,24(sp)
    80003c7a:	e84a                	sd	s2,16(sp)
    80003c7c:	e44e                	sd	s3,8(sp)
    80003c7e:	1800                	addi	s0,sp,48
    80003c80:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c82:	4585                	li	a1,1
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	a3e080e7          	jalr	-1474(ra) # 800036c2 <bread>
    80003c8c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c8e:	00026997          	auipc	s3,0x26
    80003c92:	10a98993          	addi	s3,s3,266 # 80029d98 <sb>
    80003c96:	02000613          	li	a2,32
    80003c9a:	05850593          	addi	a1,a0,88
    80003c9e:	854e                	mv	a0,s3
    80003ca0:	ffffd097          	auipc	ra,0xffffd
    80003ca4:	0f0080e7          	jalr	240(ra) # 80000d90 <memmove>
  brelse(bp);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	b48080e7          	jalr	-1208(ra) # 800037f2 <brelse>
  if(sb.magic != FSMAGIC)
    80003cb2:	0009a703          	lw	a4,0(s3)
    80003cb6:	102037b7          	lui	a5,0x10203
    80003cba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cbe:	02f71263          	bne	a4,a5,80003ce2 <fsinit+0x70>
  initlog(dev, &sb);
    80003cc2:	00026597          	auipc	a1,0x26
    80003cc6:	0d658593          	addi	a1,a1,214 # 80029d98 <sb>
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	b60080e7          	jalr	-1184(ra) # 8000482c <initlog>
}
    80003cd4:	70a2                	ld	ra,40(sp)
    80003cd6:	7402                	ld	s0,32(sp)
    80003cd8:	64e2                	ld	s1,24(sp)
    80003cda:	6942                	ld	s2,16(sp)
    80003cdc:	69a2                	ld	s3,8(sp)
    80003cde:	6145                	addi	sp,sp,48
    80003ce0:	8082                	ret
    panic("invalid file system");
    80003ce2:	00004517          	auipc	a0,0x4
    80003ce6:	79650513          	addi	a0,a0,1942 # 80008478 <etext+0x478>
    80003cea:	ffffd097          	auipc	ra,0xffffd
    80003cee:	876080e7          	jalr	-1930(ra) # 80000560 <panic>

0000000080003cf2 <iinit>:
{
    80003cf2:	7179                	addi	sp,sp,-48
    80003cf4:	f406                	sd	ra,40(sp)
    80003cf6:	f022                	sd	s0,32(sp)
    80003cf8:	ec26                	sd	s1,24(sp)
    80003cfa:	e84a                	sd	s2,16(sp)
    80003cfc:	e44e                	sd	s3,8(sp)
    80003cfe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d00:	00004597          	auipc	a1,0x4
    80003d04:	79058593          	addi	a1,a1,1936 # 80008490 <etext+0x490>
    80003d08:	00026517          	auipc	a0,0x26
    80003d0c:	0b050513          	addi	a0,a0,176 # 80029db8 <itable>
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	e98080e7          	jalr	-360(ra) # 80000ba8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d18:	00026497          	auipc	s1,0x26
    80003d1c:	0c848493          	addi	s1,s1,200 # 80029de0 <itable+0x28>
    80003d20:	00028997          	auipc	s3,0x28
    80003d24:	b5098993          	addi	s3,s3,-1200 # 8002b870 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d28:	00004917          	auipc	s2,0x4
    80003d2c:	77090913          	addi	s2,s2,1904 # 80008498 <etext+0x498>
    80003d30:	85ca                	mv	a1,s2
    80003d32:	8526                	mv	a0,s1
    80003d34:	00001097          	auipc	ra,0x1
    80003d38:	e4c080e7          	jalr	-436(ra) # 80004b80 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d3c:	08848493          	addi	s1,s1,136
    80003d40:	ff3498e3          	bne	s1,s3,80003d30 <iinit+0x3e>
}
    80003d44:	70a2                	ld	ra,40(sp)
    80003d46:	7402                	ld	s0,32(sp)
    80003d48:	64e2                	ld	s1,24(sp)
    80003d4a:	6942                	ld	s2,16(sp)
    80003d4c:	69a2                	ld	s3,8(sp)
    80003d4e:	6145                	addi	sp,sp,48
    80003d50:	8082                	ret

0000000080003d52 <ialloc>:
{
    80003d52:	7139                	addi	sp,sp,-64
    80003d54:	fc06                	sd	ra,56(sp)
    80003d56:	f822                	sd	s0,48(sp)
    80003d58:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d5a:	00026717          	auipc	a4,0x26
    80003d5e:	04a72703          	lw	a4,74(a4) # 80029da4 <sb+0xc>
    80003d62:	4785                	li	a5,1
    80003d64:	06e7f463          	bgeu	a5,a4,80003dcc <ialloc+0x7a>
    80003d68:	f426                	sd	s1,40(sp)
    80003d6a:	f04a                	sd	s2,32(sp)
    80003d6c:	ec4e                	sd	s3,24(sp)
    80003d6e:	e852                	sd	s4,16(sp)
    80003d70:	e456                	sd	s5,8(sp)
    80003d72:	e05a                	sd	s6,0(sp)
    80003d74:	8aaa                	mv	s5,a0
    80003d76:	8b2e                	mv	s6,a1
    80003d78:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d7a:	00026a17          	auipc	s4,0x26
    80003d7e:	01ea0a13          	addi	s4,s4,30 # 80029d98 <sb>
    80003d82:	00495593          	srli	a1,s2,0x4
    80003d86:	018a2783          	lw	a5,24(s4)
    80003d8a:	9dbd                	addw	a1,a1,a5
    80003d8c:	8556                	mv	a0,s5
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	934080e7          	jalr	-1740(ra) # 800036c2 <bread>
    80003d96:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d98:	05850993          	addi	s3,a0,88
    80003d9c:	00f97793          	andi	a5,s2,15
    80003da0:	079a                	slli	a5,a5,0x6
    80003da2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003da4:	00099783          	lh	a5,0(s3)
    80003da8:	cf9d                	beqz	a5,80003de6 <ialloc+0x94>
    brelse(bp);
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	a48080e7          	jalr	-1464(ra) # 800037f2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003db2:	0905                	addi	s2,s2,1
    80003db4:	00ca2703          	lw	a4,12(s4)
    80003db8:	0009079b          	sext.w	a5,s2
    80003dbc:	fce7e3e3          	bltu	a5,a4,80003d82 <ialloc+0x30>
    80003dc0:	74a2                	ld	s1,40(sp)
    80003dc2:	7902                	ld	s2,32(sp)
    80003dc4:	69e2                	ld	s3,24(sp)
    80003dc6:	6a42                	ld	s4,16(sp)
    80003dc8:	6aa2                	ld	s5,8(sp)
    80003dca:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003dcc:	00004517          	auipc	a0,0x4
    80003dd0:	6d450513          	addi	a0,a0,1748 # 800084a0 <etext+0x4a0>
    80003dd4:	ffffc097          	auipc	ra,0xffffc
    80003dd8:	7d6080e7          	jalr	2006(ra) # 800005aa <printf>
  return 0;
    80003ddc:	4501                	li	a0,0
}
    80003dde:	70e2                	ld	ra,56(sp)
    80003de0:	7442                	ld	s0,48(sp)
    80003de2:	6121                	addi	sp,sp,64
    80003de4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003de6:	04000613          	li	a2,64
    80003dea:	4581                	li	a1,0
    80003dec:	854e                	mv	a0,s3
    80003dee:	ffffd097          	auipc	ra,0xffffd
    80003df2:	f46080e7          	jalr	-186(ra) # 80000d34 <memset>
      dip->type = type;
    80003df6:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dfa:	8526                	mv	a0,s1
    80003dfc:	00001097          	auipc	ra,0x1
    80003e00:	ca0080e7          	jalr	-864(ra) # 80004a9c <log_write>
      brelse(bp);
    80003e04:	8526                	mv	a0,s1
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	9ec080e7          	jalr	-1556(ra) # 800037f2 <brelse>
      return iget(dev, inum);
    80003e0e:	0009059b          	sext.w	a1,s2
    80003e12:	8556                	mv	a0,s5
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	da2080e7          	jalr	-606(ra) # 80003bb6 <iget>
    80003e1c:	74a2                	ld	s1,40(sp)
    80003e1e:	7902                	ld	s2,32(sp)
    80003e20:	69e2                	ld	s3,24(sp)
    80003e22:	6a42                	ld	s4,16(sp)
    80003e24:	6aa2                	ld	s5,8(sp)
    80003e26:	6b02                	ld	s6,0(sp)
    80003e28:	bf5d                	j	80003dde <ialloc+0x8c>

0000000080003e2a <iupdate>:
{
    80003e2a:	1101                	addi	sp,sp,-32
    80003e2c:	ec06                	sd	ra,24(sp)
    80003e2e:	e822                	sd	s0,16(sp)
    80003e30:	e426                	sd	s1,8(sp)
    80003e32:	e04a                	sd	s2,0(sp)
    80003e34:	1000                	addi	s0,sp,32
    80003e36:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e38:	415c                	lw	a5,4(a0)
    80003e3a:	0047d79b          	srliw	a5,a5,0x4
    80003e3e:	00026597          	auipc	a1,0x26
    80003e42:	f725a583          	lw	a1,-142(a1) # 80029db0 <sb+0x18>
    80003e46:	9dbd                	addw	a1,a1,a5
    80003e48:	4108                	lw	a0,0(a0)
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	878080e7          	jalr	-1928(ra) # 800036c2 <bread>
    80003e52:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e54:	05850793          	addi	a5,a0,88
    80003e58:	40d8                	lw	a4,4(s1)
    80003e5a:	8b3d                	andi	a4,a4,15
    80003e5c:	071a                	slli	a4,a4,0x6
    80003e5e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003e60:	04449703          	lh	a4,68(s1)
    80003e64:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003e68:	04649703          	lh	a4,70(s1)
    80003e6c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003e70:	04849703          	lh	a4,72(s1)
    80003e74:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003e78:	04a49703          	lh	a4,74(s1)
    80003e7c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003e80:	44f8                	lw	a4,76(s1)
    80003e82:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e84:	03400613          	li	a2,52
    80003e88:	05048593          	addi	a1,s1,80
    80003e8c:	00c78513          	addi	a0,a5,12
    80003e90:	ffffd097          	auipc	ra,0xffffd
    80003e94:	f00080e7          	jalr	-256(ra) # 80000d90 <memmove>
  log_write(bp);
    80003e98:	854a                	mv	a0,s2
    80003e9a:	00001097          	auipc	ra,0x1
    80003e9e:	c02080e7          	jalr	-1022(ra) # 80004a9c <log_write>
  brelse(bp);
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	94e080e7          	jalr	-1714(ra) # 800037f2 <brelse>
}
    80003eac:	60e2                	ld	ra,24(sp)
    80003eae:	6442                	ld	s0,16(sp)
    80003eb0:	64a2                	ld	s1,8(sp)
    80003eb2:	6902                	ld	s2,0(sp)
    80003eb4:	6105                	addi	sp,sp,32
    80003eb6:	8082                	ret

0000000080003eb8 <idup>:
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	e426                	sd	s1,8(sp)
    80003ec0:	1000                	addi	s0,sp,32
    80003ec2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ec4:	00026517          	auipc	a0,0x26
    80003ec8:	ef450513          	addi	a0,a0,-268 # 80029db8 <itable>
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	d6c080e7          	jalr	-660(ra) # 80000c38 <acquire>
  ip->ref++;
    80003ed4:	449c                	lw	a5,8(s1)
    80003ed6:	2785                	addiw	a5,a5,1
    80003ed8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eda:	00026517          	auipc	a0,0x26
    80003ede:	ede50513          	addi	a0,a0,-290 # 80029db8 <itable>
    80003ee2:	ffffd097          	auipc	ra,0xffffd
    80003ee6:	e0a080e7          	jalr	-502(ra) # 80000cec <release>
}
    80003eea:	8526                	mv	a0,s1
    80003eec:	60e2                	ld	ra,24(sp)
    80003eee:	6442                	ld	s0,16(sp)
    80003ef0:	64a2                	ld	s1,8(sp)
    80003ef2:	6105                	addi	sp,sp,32
    80003ef4:	8082                	ret

0000000080003ef6 <ilock>:
{
    80003ef6:	1101                	addi	sp,sp,-32
    80003ef8:	ec06                	sd	ra,24(sp)
    80003efa:	e822                	sd	s0,16(sp)
    80003efc:	e426                	sd	s1,8(sp)
    80003efe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f00:	c10d                	beqz	a0,80003f22 <ilock+0x2c>
    80003f02:	84aa                	mv	s1,a0
    80003f04:	451c                	lw	a5,8(a0)
    80003f06:	00f05e63          	blez	a5,80003f22 <ilock+0x2c>
  acquiresleep(&ip->lock);
    80003f0a:	0541                	addi	a0,a0,16
    80003f0c:	00001097          	auipc	ra,0x1
    80003f10:	cae080e7          	jalr	-850(ra) # 80004bba <acquiresleep>
  if(ip->valid == 0){
    80003f14:	40bc                	lw	a5,64(s1)
    80003f16:	cf99                	beqz	a5,80003f34 <ilock+0x3e>
}
    80003f18:	60e2                	ld	ra,24(sp)
    80003f1a:	6442                	ld	s0,16(sp)
    80003f1c:	64a2                	ld	s1,8(sp)
    80003f1e:	6105                	addi	sp,sp,32
    80003f20:	8082                	ret
    80003f22:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003f24:	00004517          	auipc	a0,0x4
    80003f28:	59450513          	addi	a0,a0,1428 # 800084b8 <etext+0x4b8>
    80003f2c:	ffffc097          	auipc	ra,0xffffc
    80003f30:	634080e7          	jalr	1588(ra) # 80000560 <panic>
    80003f34:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f36:	40dc                	lw	a5,4(s1)
    80003f38:	0047d79b          	srliw	a5,a5,0x4
    80003f3c:	00026597          	auipc	a1,0x26
    80003f40:	e745a583          	lw	a1,-396(a1) # 80029db0 <sb+0x18>
    80003f44:	9dbd                	addw	a1,a1,a5
    80003f46:	4088                	lw	a0,0(s1)
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	77a080e7          	jalr	1914(ra) # 800036c2 <bread>
    80003f50:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f52:	05850593          	addi	a1,a0,88
    80003f56:	40dc                	lw	a5,4(s1)
    80003f58:	8bbd                	andi	a5,a5,15
    80003f5a:	079a                	slli	a5,a5,0x6
    80003f5c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f5e:	00059783          	lh	a5,0(a1)
    80003f62:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f66:	00259783          	lh	a5,2(a1)
    80003f6a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f6e:	00459783          	lh	a5,4(a1)
    80003f72:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f76:	00659783          	lh	a5,6(a1)
    80003f7a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f7e:	459c                	lw	a5,8(a1)
    80003f80:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f82:	03400613          	li	a2,52
    80003f86:	05b1                	addi	a1,a1,12
    80003f88:	05048513          	addi	a0,s1,80
    80003f8c:	ffffd097          	auipc	ra,0xffffd
    80003f90:	e04080e7          	jalr	-508(ra) # 80000d90 <memmove>
    brelse(bp);
    80003f94:	854a                	mv	a0,s2
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	85c080e7          	jalr	-1956(ra) # 800037f2 <brelse>
    ip->valid = 1;
    80003f9e:	4785                	li	a5,1
    80003fa0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fa2:	04449783          	lh	a5,68(s1)
    80003fa6:	c399                	beqz	a5,80003fac <ilock+0xb6>
    80003fa8:	6902                	ld	s2,0(sp)
    80003faa:	b7bd                	j	80003f18 <ilock+0x22>
      panic("ilock: no type");
    80003fac:	00004517          	auipc	a0,0x4
    80003fb0:	51450513          	addi	a0,a0,1300 # 800084c0 <etext+0x4c0>
    80003fb4:	ffffc097          	auipc	ra,0xffffc
    80003fb8:	5ac080e7          	jalr	1452(ra) # 80000560 <panic>

0000000080003fbc <iunlock>:
{
    80003fbc:	1101                	addi	sp,sp,-32
    80003fbe:	ec06                	sd	ra,24(sp)
    80003fc0:	e822                	sd	s0,16(sp)
    80003fc2:	e426                	sd	s1,8(sp)
    80003fc4:	e04a                	sd	s2,0(sp)
    80003fc6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fc8:	c905                	beqz	a0,80003ff8 <iunlock+0x3c>
    80003fca:	84aa                	mv	s1,a0
    80003fcc:	01050913          	addi	s2,a0,16
    80003fd0:	854a                	mv	a0,s2
    80003fd2:	00001097          	auipc	ra,0x1
    80003fd6:	c82080e7          	jalr	-894(ra) # 80004c54 <holdingsleep>
    80003fda:	cd19                	beqz	a0,80003ff8 <iunlock+0x3c>
    80003fdc:	449c                	lw	a5,8(s1)
    80003fde:	00f05d63          	blez	a5,80003ff8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fe2:	854a                	mv	a0,s2
    80003fe4:	00001097          	auipc	ra,0x1
    80003fe8:	c2c080e7          	jalr	-980(ra) # 80004c10 <releasesleep>
}
    80003fec:	60e2                	ld	ra,24(sp)
    80003fee:	6442                	ld	s0,16(sp)
    80003ff0:	64a2                	ld	s1,8(sp)
    80003ff2:	6902                	ld	s2,0(sp)
    80003ff4:	6105                	addi	sp,sp,32
    80003ff6:	8082                	ret
    panic("iunlock");
    80003ff8:	00004517          	auipc	a0,0x4
    80003ffc:	4d850513          	addi	a0,a0,1240 # 800084d0 <etext+0x4d0>
    80004000:	ffffc097          	auipc	ra,0xffffc
    80004004:	560080e7          	jalr	1376(ra) # 80000560 <panic>

0000000080004008 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004008:	7179                	addi	sp,sp,-48
    8000400a:	f406                	sd	ra,40(sp)
    8000400c:	f022                	sd	s0,32(sp)
    8000400e:	ec26                	sd	s1,24(sp)
    80004010:	e84a                	sd	s2,16(sp)
    80004012:	e44e                	sd	s3,8(sp)
    80004014:	1800                	addi	s0,sp,48
    80004016:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004018:	05050493          	addi	s1,a0,80
    8000401c:	08050913          	addi	s2,a0,128
    80004020:	a021                	j	80004028 <itrunc+0x20>
    80004022:	0491                	addi	s1,s1,4
    80004024:	01248d63          	beq	s1,s2,8000403e <itrunc+0x36>
    if(ip->addrs[i]){
    80004028:	408c                	lw	a1,0(s1)
    8000402a:	dde5                	beqz	a1,80004022 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    8000402c:	0009a503          	lw	a0,0(s3)
    80004030:	00000097          	auipc	ra,0x0
    80004034:	8d6080e7          	jalr	-1834(ra) # 80003906 <bfree>
      ip->addrs[i] = 0;
    80004038:	0004a023          	sw	zero,0(s1)
    8000403c:	b7dd                	j	80004022 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000403e:	0809a583          	lw	a1,128(s3)
    80004042:	ed99                	bnez	a1,80004060 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004044:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004048:	854e                	mv	a0,s3
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	de0080e7          	jalr	-544(ra) # 80003e2a <iupdate>
}
    80004052:	70a2                	ld	ra,40(sp)
    80004054:	7402                	ld	s0,32(sp)
    80004056:	64e2                	ld	s1,24(sp)
    80004058:	6942                	ld	s2,16(sp)
    8000405a:	69a2                	ld	s3,8(sp)
    8000405c:	6145                	addi	sp,sp,48
    8000405e:	8082                	ret
    80004060:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004062:	0009a503          	lw	a0,0(s3)
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	65c080e7          	jalr	1628(ra) # 800036c2 <bread>
    8000406e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004070:	05850493          	addi	s1,a0,88
    80004074:	45850913          	addi	s2,a0,1112
    80004078:	a021                	j	80004080 <itrunc+0x78>
    8000407a:	0491                	addi	s1,s1,4
    8000407c:	01248b63          	beq	s1,s2,80004092 <itrunc+0x8a>
      if(a[j])
    80004080:	408c                	lw	a1,0(s1)
    80004082:	dde5                	beqz	a1,8000407a <itrunc+0x72>
        bfree(ip->dev, a[j]);
    80004084:	0009a503          	lw	a0,0(s3)
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	87e080e7          	jalr	-1922(ra) # 80003906 <bfree>
    80004090:	b7ed                	j	8000407a <itrunc+0x72>
    brelse(bp);
    80004092:	8552                	mv	a0,s4
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	75e080e7          	jalr	1886(ra) # 800037f2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000409c:	0809a583          	lw	a1,128(s3)
    800040a0:	0009a503          	lw	a0,0(s3)
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	862080e7          	jalr	-1950(ra) # 80003906 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040ac:	0809a023          	sw	zero,128(s3)
    800040b0:	6a02                	ld	s4,0(sp)
    800040b2:	bf49                	j	80004044 <itrunc+0x3c>

00000000800040b4 <iput>:
{
    800040b4:	1101                	addi	sp,sp,-32
    800040b6:	ec06                	sd	ra,24(sp)
    800040b8:	e822                	sd	s0,16(sp)
    800040ba:	e426                	sd	s1,8(sp)
    800040bc:	1000                	addi	s0,sp,32
    800040be:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040c0:	00026517          	auipc	a0,0x26
    800040c4:	cf850513          	addi	a0,a0,-776 # 80029db8 <itable>
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	b70080e7          	jalr	-1168(ra) # 80000c38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d0:	4498                	lw	a4,8(s1)
    800040d2:	4785                	li	a5,1
    800040d4:	02f70263          	beq	a4,a5,800040f8 <iput+0x44>
  ip->ref--;
    800040d8:	449c                	lw	a5,8(s1)
    800040da:	37fd                	addiw	a5,a5,-1
    800040dc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040de:	00026517          	auipc	a0,0x26
    800040e2:	cda50513          	addi	a0,a0,-806 # 80029db8 <itable>
    800040e6:	ffffd097          	auipc	ra,0xffffd
    800040ea:	c06080e7          	jalr	-1018(ra) # 80000cec <release>
}
    800040ee:	60e2                	ld	ra,24(sp)
    800040f0:	6442                	ld	s0,16(sp)
    800040f2:	64a2                	ld	s1,8(sp)
    800040f4:	6105                	addi	sp,sp,32
    800040f6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040f8:	40bc                	lw	a5,64(s1)
    800040fa:	dff9                	beqz	a5,800040d8 <iput+0x24>
    800040fc:	04a49783          	lh	a5,74(s1)
    80004100:	ffe1                	bnez	a5,800040d8 <iput+0x24>
    80004102:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80004104:	01048913          	addi	s2,s1,16
    80004108:	854a                	mv	a0,s2
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	ab0080e7          	jalr	-1360(ra) # 80004bba <acquiresleep>
    release(&itable.lock);
    80004112:	00026517          	auipc	a0,0x26
    80004116:	ca650513          	addi	a0,a0,-858 # 80029db8 <itable>
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	bd2080e7          	jalr	-1070(ra) # 80000cec <release>
    itrunc(ip);
    80004122:	8526                	mv	a0,s1
    80004124:	00000097          	auipc	ra,0x0
    80004128:	ee4080e7          	jalr	-284(ra) # 80004008 <itrunc>
    ip->type = 0;
    8000412c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004130:	8526                	mv	a0,s1
    80004132:	00000097          	auipc	ra,0x0
    80004136:	cf8080e7          	jalr	-776(ra) # 80003e2a <iupdate>
    ip->valid = 0;
    8000413a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000413e:	854a                	mv	a0,s2
    80004140:	00001097          	auipc	ra,0x1
    80004144:	ad0080e7          	jalr	-1328(ra) # 80004c10 <releasesleep>
    acquire(&itable.lock);
    80004148:	00026517          	auipc	a0,0x26
    8000414c:	c7050513          	addi	a0,a0,-912 # 80029db8 <itable>
    80004150:	ffffd097          	auipc	ra,0xffffd
    80004154:	ae8080e7          	jalr	-1304(ra) # 80000c38 <acquire>
    80004158:	6902                	ld	s2,0(sp)
    8000415a:	bfbd                	j	800040d8 <iput+0x24>

000000008000415c <iunlockput>:
{
    8000415c:	1101                	addi	sp,sp,-32
    8000415e:	ec06                	sd	ra,24(sp)
    80004160:	e822                	sd	s0,16(sp)
    80004162:	e426                	sd	s1,8(sp)
    80004164:	1000                	addi	s0,sp,32
    80004166:	84aa                	mv	s1,a0
  iunlock(ip);
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	e54080e7          	jalr	-428(ra) # 80003fbc <iunlock>
  iput(ip);
    80004170:	8526                	mv	a0,s1
    80004172:	00000097          	auipc	ra,0x0
    80004176:	f42080e7          	jalr	-190(ra) # 800040b4 <iput>
}
    8000417a:	60e2                	ld	ra,24(sp)
    8000417c:	6442                	ld	s0,16(sp)
    8000417e:	64a2                	ld	s1,8(sp)
    80004180:	6105                	addi	sp,sp,32
    80004182:	8082                	ret

0000000080004184 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004184:	1141                	addi	sp,sp,-16
    80004186:	e422                	sd	s0,8(sp)
    80004188:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000418a:	411c                	lw	a5,0(a0)
    8000418c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000418e:	415c                	lw	a5,4(a0)
    80004190:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004192:	04451783          	lh	a5,68(a0)
    80004196:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000419a:	04a51783          	lh	a5,74(a0)
    8000419e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041a2:	04c56783          	lwu	a5,76(a0)
    800041a6:	e99c                	sd	a5,16(a1)
}
    800041a8:	6422                	ld	s0,8(sp)
    800041aa:	0141                	addi	sp,sp,16
    800041ac:	8082                	ret

00000000800041ae <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041ae:	457c                	lw	a5,76(a0)
    800041b0:	10d7e563          	bltu	a5,a3,800042ba <readi+0x10c>
{
    800041b4:	7159                	addi	sp,sp,-112
    800041b6:	f486                	sd	ra,104(sp)
    800041b8:	f0a2                	sd	s0,96(sp)
    800041ba:	eca6                	sd	s1,88(sp)
    800041bc:	e0d2                	sd	s4,64(sp)
    800041be:	fc56                	sd	s5,56(sp)
    800041c0:	f85a                	sd	s6,48(sp)
    800041c2:	f45e                	sd	s7,40(sp)
    800041c4:	1880                	addi	s0,sp,112
    800041c6:	8b2a                	mv	s6,a0
    800041c8:	8bae                	mv	s7,a1
    800041ca:	8a32                	mv	s4,a2
    800041cc:	84b6                	mv	s1,a3
    800041ce:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800041d0:	9f35                	addw	a4,a4,a3
    return 0;
    800041d2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041d4:	0cd76a63          	bltu	a4,a3,800042a8 <readi+0xfa>
    800041d8:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    800041da:	00e7f463          	bgeu	a5,a4,800041e2 <readi+0x34>
    n = ip->size - off;
    800041de:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041e2:	0a0a8963          	beqz	s5,80004294 <readi+0xe6>
    800041e6:	e8ca                	sd	s2,80(sp)
    800041e8:	f062                	sd	s8,32(sp)
    800041ea:	ec66                	sd	s9,24(sp)
    800041ec:	e86a                	sd	s10,16(sp)
    800041ee:	e46e                	sd	s11,8(sp)
    800041f0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041f2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041f6:	5c7d                	li	s8,-1
    800041f8:	a82d                	j	80004232 <readi+0x84>
    800041fa:	020d1d93          	slli	s11,s10,0x20
    800041fe:	020ddd93          	srli	s11,s11,0x20
    80004202:	05890613          	addi	a2,s2,88
    80004206:	86ee                	mv	a3,s11
    80004208:	963a                	add	a2,a2,a4
    8000420a:	85d2                	mv	a1,s4
    8000420c:	855e                	mv	a0,s7
    8000420e:	ffffe097          	auipc	ra,0xffffe
    80004212:	70a080e7          	jalr	1802(ra) # 80002918 <either_copyout>
    80004216:	05850d63          	beq	a0,s8,80004270 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000421a:	854a                	mv	a0,s2
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	5d6080e7          	jalr	1494(ra) # 800037f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004224:	013d09bb          	addw	s3,s10,s3
    80004228:	009d04bb          	addw	s1,s10,s1
    8000422c:	9a6e                	add	s4,s4,s11
    8000422e:	0559fd63          	bgeu	s3,s5,80004288 <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    80004232:	00a4d59b          	srliw	a1,s1,0xa
    80004236:	855a                	mv	a0,s6
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	88e080e7          	jalr	-1906(ra) # 80003ac6 <bmap>
    80004240:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004244:	c9b1                	beqz	a1,80004298 <readi+0xea>
    bp = bread(ip->dev, addr);
    80004246:	000b2503          	lw	a0,0(s6)
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	478080e7          	jalr	1144(ra) # 800036c2 <bread>
    80004252:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004254:	3ff4f713          	andi	a4,s1,1023
    80004258:	40ec87bb          	subw	a5,s9,a4
    8000425c:	413a86bb          	subw	a3,s5,s3
    80004260:	8d3e                	mv	s10,a5
    80004262:	2781                	sext.w	a5,a5
    80004264:	0006861b          	sext.w	a2,a3
    80004268:	f8f679e3          	bgeu	a2,a5,800041fa <readi+0x4c>
    8000426c:	8d36                	mv	s10,a3
    8000426e:	b771                	j	800041fa <readi+0x4c>
      brelse(bp);
    80004270:	854a                	mv	a0,s2
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	580080e7          	jalr	1408(ra) # 800037f2 <brelse>
      tot = -1;
    8000427a:	59fd                	li	s3,-1
      break;
    8000427c:	6946                	ld	s2,80(sp)
    8000427e:	7c02                	ld	s8,32(sp)
    80004280:	6ce2                	ld	s9,24(sp)
    80004282:	6d42                	ld	s10,16(sp)
    80004284:	6da2                	ld	s11,8(sp)
    80004286:	a831                	j	800042a2 <readi+0xf4>
    80004288:	6946                	ld	s2,80(sp)
    8000428a:	7c02                	ld	s8,32(sp)
    8000428c:	6ce2                	ld	s9,24(sp)
    8000428e:	6d42                	ld	s10,16(sp)
    80004290:	6da2                	ld	s11,8(sp)
    80004292:	a801                	j	800042a2 <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004294:	89d6                	mv	s3,s5
    80004296:	a031                	j	800042a2 <readi+0xf4>
    80004298:	6946                	ld	s2,80(sp)
    8000429a:	7c02                	ld	s8,32(sp)
    8000429c:	6ce2                	ld	s9,24(sp)
    8000429e:	6d42                	ld	s10,16(sp)
    800042a0:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800042a2:	0009851b          	sext.w	a0,s3
    800042a6:	69a6                	ld	s3,72(sp)
}
    800042a8:	70a6                	ld	ra,104(sp)
    800042aa:	7406                	ld	s0,96(sp)
    800042ac:	64e6                	ld	s1,88(sp)
    800042ae:	6a06                	ld	s4,64(sp)
    800042b0:	7ae2                	ld	s5,56(sp)
    800042b2:	7b42                	ld	s6,48(sp)
    800042b4:	7ba2                	ld	s7,40(sp)
    800042b6:	6165                	addi	sp,sp,112
    800042b8:	8082                	ret
    return 0;
    800042ba:	4501                	li	a0,0
}
    800042bc:	8082                	ret

00000000800042be <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042be:	457c                	lw	a5,76(a0)
    800042c0:	10d7ee63          	bltu	a5,a3,800043dc <writei+0x11e>
{
    800042c4:	7159                	addi	sp,sp,-112
    800042c6:	f486                	sd	ra,104(sp)
    800042c8:	f0a2                	sd	s0,96(sp)
    800042ca:	e8ca                	sd	s2,80(sp)
    800042cc:	e0d2                	sd	s4,64(sp)
    800042ce:	fc56                	sd	s5,56(sp)
    800042d0:	f85a                	sd	s6,48(sp)
    800042d2:	f45e                	sd	s7,40(sp)
    800042d4:	1880                	addi	s0,sp,112
    800042d6:	8aaa                	mv	s5,a0
    800042d8:	8bae                	mv	s7,a1
    800042da:	8a32                	mv	s4,a2
    800042dc:	8936                	mv	s2,a3
    800042de:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042e0:	00e687bb          	addw	a5,a3,a4
    800042e4:	0ed7ee63          	bltu	a5,a3,800043e0 <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042e8:	00043737          	lui	a4,0x43
    800042ec:	0ef76c63          	bltu	a4,a5,800043e4 <writei+0x126>
    800042f0:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042f2:	0c0b0d63          	beqz	s6,800043cc <writei+0x10e>
    800042f6:	eca6                	sd	s1,88(sp)
    800042f8:	f062                	sd	s8,32(sp)
    800042fa:	ec66                	sd	s9,24(sp)
    800042fc:	e86a                	sd	s10,16(sp)
    800042fe:	e46e                	sd	s11,8(sp)
    80004300:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004302:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004306:	5c7d                	li	s8,-1
    80004308:	a091                	j	8000434c <writei+0x8e>
    8000430a:	020d1d93          	slli	s11,s10,0x20
    8000430e:	020ddd93          	srli	s11,s11,0x20
    80004312:	05848513          	addi	a0,s1,88
    80004316:	86ee                	mv	a3,s11
    80004318:	8652                	mv	a2,s4
    8000431a:	85de                	mv	a1,s7
    8000431c:	953a                	add	a0,a0,a4
    8000431e:	ffffe097          	auipc	ra,0xffffe
    80004322:	652080e7          	jalr	1618(ra) # 80002970 <either_copyin>
    80004326:	07850263          	beq	a0,s8,8000438a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000432a:	8526                	mv	a0,s1
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	770080e7          	jalr	1904(ra) # 80004a9c <log_write>
    brelse(bp);
    80004334:	8526                	mv	a0,s1
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	4bc080e7          	jalr	1212(ra) # 800037f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000433e:	013d09bb          	addw	s3,s10,s3
    80004342:	012d093b          	addw	s2,s10,s2
    80004346:	9a6e                	add	s4,s4,s11
    80004348:	0569f663          	bgeu	s3,s6,80004394 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000434c:	00a9559b          	srliw	a1,s2,0xa
    80004350:	8556                	mv	a0,s5
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	774080e7          	jalr	1908(ra) # 80003ac6 <bmap>
    8000435a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000435e:	c99d                	beqz	a1,80004394 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004360:	000aa503          	lw	a0,0(s5)
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	35e080e7          	jalr	862(ra) # 800036c2 <bread>
    8000436c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000436e:	3ff97713          	andi	a4,s2,1023
    80004372:	40ec87bb          	subw	a5,s9,a4
    80004376:	413b06bb          	subw	a3,s6,s3
    8000437a:	8d3e                	mv	s10,a5
    8000437c:	2781                	sext.w	a5,a5
    8000437e:	0006861b          	sext.w	a2,a3
    80004382:	f8f674e3          	bgeu	a2,a5,8000430a <writei+0x4c>
    80004386:	8d36                	mv	s10,a3
    80004388:	b749                	j	8000430a <writei+0x4c>
      brelse(bp);
    8000438a:	8526                	mv	a0,s1
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	466080e7          	jalr	1126(ra) # 800037f2 <brelse>
  }

  if(off > ip->size)
    80004394:	04caa783          	lw	a5,76(s5)
    80004398:	0327fc63          	bgeu	a5,s2,800043d0 <writei+0x112>
    ip->size = off;
    8000439c:	052aa623          	sw	s2,76(s5)
    800043a0:	64e6                	ld	s1,88(sp)
    800043a2:	7c02                	ld	s8,32(sp)
    800043a4:	6ce2                	ld	s9,24(sp)
    800043a6:	6d42                	ld	s10,16(sp)
    800043a8:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043aa:	8556                	mv	a0,s5
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	a7e080e7          	jalr	-1410(ra) # 80003e2a <iupdate>

  return tot;
    800043b4:	0009851b          	sext.w	a0,s3
    800043b8:	69a6                	ld	s3,72(sp)
}
    800043ba:	70a6                	ld	ra,104(sp)
    800043bc:	7406                	ld	s0,96(sp)
    800043be:	6946                	ld	s2,80(sp)
    800043c0:	6a06                	ld	s4,64(sp)
    800043c2:	7ae2                	ld	s5,56(sp)
    800043c4:	7b42                	ld	s6,48(sp)
    800043c6:	7ba2                	ld	s7,40(sp)
    800043c8:	6165                	addi	sp,sp,112
    800043ca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043cc:	89da                	mv	s3,s6
    800043ce:	bff1                	j	800043aa <writei+0xec>
    800043d0:	64e6                	ld	s1,88(sp)
    800043d2:	7c02                	ld	s8,32(sp)
    800043d4:	6ce2                	ld	s9,24(sp)
    800043d6:	6d42                	ld	s10,16(sp)
    800043d8:	6da2                	ld	s11,8(sp)
    800043da:	bfc1                	j	800043aa <writei+0xec>
    return -1;
    800043dc:	557d                	li	a0,-1
}
    800043de:	8082                	ret
    return -1;
    800043e0:	557d                	li	a0,-1
    800043e2:	bfe1                	j	800043ba <writei+0xfc>
    return -1;
    800043e4:	557d                	li	a0,-1
    800043e6:	bfd1                	j	800043ba <writei+0xfc>

00000000800043e8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043e8:	1141                	addi	sp,sp,-16
    800043ea:	e406                	sd	ra,8(sp)
    800043ec:	e022                	sd	s0,0(sp)
    800043ee:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043f0:	4639                	li	a2,14
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	a12080e7          	jalr	-1518(ra) # 80000e04 <strncmp>
}
    800043fa:	60a2                	ld	ra,8(sp)
    800043fc:	6402                	ld	s0,0(sp)
    800043fe:	0141                	addi	sp,sp,16
    80004400:	8082                	ret

0000000080004402 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004402:	7139                	addi	sp,sp,-64
    80004404:	fc06                	sd	ra,56(sp)
    80004406:	f822                	sd	s0,48(sp)
    80004408:	f426                	sd	s1,40(sp)
    8000440a:	f04a                	sd	s2,32(sp)
    8000440c:	ec4e                	sd	s3,24(sp)
    8000440e:	e852                	sd	s4,16(sp)
    80004410:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004412:	04451703          	lh	a4,68(a0)
    80004416:	4785                	li	a5,1
    80004418:	00f71a63          	bne	a4,a5,8000442c <dirlookup+0x2a>
    8000441c:	892a                	mv	s2,a0
    8000441e:	89ae                	mv	s3,a1
    80004420:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004422:	457c                	lw	a5,76(a0)
    80004424:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004426:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004428:	e79d                	bnez	a5,80004456 <dirlookup+0x54>
    8000442a:	a8a5                	j	800044a2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000442c:	00004517          	auipc	a0,0x4
    80004430:	0ac50513          	addi	a0,a0,172 # 800084d8 <etext+0x4d8>
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	12c080e7          	jalr	300(ra) # 80000560 <panic>
      panic("dirlookup read");
    8000443c:	00004517          	auipc	a0,0x4
    80004440:	0b450513          	addi	a0,a0,180 # 800084f0 <etext+0x4f0>
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	11c080e7          	jalr	284(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444c:	24c1                	addiw	s1,s1,16
    8000444e:	04c92783          	lw	a5,76(s2)
    80004452:	04f4f763          	bgeu	s1,a5,800044a0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004456:	4741                	li	a4,16
    80004458:	86a6                	mv	a3,s1
    8000445a:	fc040613          	addi	a2,s0,-64
    8000445e:	4581                	li	a1,0
    80004460:	854a                	mv	a0,s2
    80004462:	00000097          	auipc	ra,0x0
    80004466:	d4c080e7          	jalr	-692(ra) # 800041ae <readi>
    8000446a:	47c1                	li	a5,16
    8000446c:	fcf518e3          	bne	a0,a5,8000443c <dirlookup+0x3a>
    if(de.inum == 0)
    80004470:	fc045783          	lhu	a5,-64(s0)
    80004474:	dfe1                	beqz	a5,8000444c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004476:	fc240593          	addi	a1,s0,-62
    8000447a:	854e                	mv	a0,s3
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	f6c080e7          	jalr	-148(ra) # 800043e8 <namecmp>
    80004484:	f561                	bnez	a0,8000444c <dirlookup+0x4a>
      if(poff)
    80004486:	000a0463          	beqz	s4,8000448e <dirlookup+0x8c>
        *poff = off;
    8000448a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000448e:	fc045583          	lhu	a1,-64(s0)
    80004492:	00092503          	lw	a0,0(s2)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	720080e7          	jalr	1824(ra) # 80003bb6 <iget>
    8000449e:	a011                	j	800044a2 <dirlookup+0xa0>
  return 0;
    800044a0:	4501                	li	a0,0
}
    800044a2:	70e2                	ld	ra,56(sp)
    800044a4:	7442                	ld	s0,48(sp)
    800044a6:	74a2                	ld	s1,40(sp)
    800044a8:	7902                	ld	s2,32(sp)
    800044aa:	69e2                	ld	s3,24(sp)
    800044ac:	6a42                	ld	s4,16(sp)
    800044ae:	6121                	addi	sp,sp,64
    800044b0:	8082                	ret

00000000800044b2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044b2:	711d                	addi	sp,sp,-96
    800044b4:	ec86                	sd	ra,88(sp)
    800044b6:	e8a2                	sd	s0,80(sp)
    800044b8:	e4a6                	sd	s1,72(sp)
    800044ba:	e0ca                	sd	s2,64(sp)
    800044bc:	fc4e                	sd	s3,56(sp)
    800044be:	f852                	sd	s4,48(sp)
    800044c0:	f456                	sd	s5,40(sp)
    800044c2:	f05a                	sd	s6,32(sp)
    800044c4:	ec5e                	sd	s7,24(sp)
    800044c6:	e862                	sd	s8,16(sp)
    800044c8:	e466                	sd	s9,8(sp)
    800044ca:	1080                	addi	s0,sp,96
    800044cc:	84aa                	mv	s1,a0
    800044ce:	8b2e                	mv	s6,a1
    800044d0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044d2:	00054703          	lbu	a4,0(a0)
    800044d6:	02f00793          	li	a5,47
    800044da:	02f70263          	beq	a4,a5,800044fe <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044de:	ffffd097          	auipc	ra,0xffffd
    800044e2:	59c080e7          	jalr	1436(ra) # 80001a7a <myproc>
    800044e6:	32853503          	ld	a0,808(a0)
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	9ce080e7          	jalr	-1586(ra) # 80003eb8 <idup>
    800044f2:	8a2a                	mv	s4,a0
  while(*path == '/')
    800044f4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800044f8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044fa:	4b85                	li	s7,1
    800044fc:	a875                	j	800045b8 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800044fe:	4585                	li	a1,1
    80004500:	4505                	li	a0,1
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	6b4080e7          	jalr	1716(ra) # 80003bb6 <iget>
    8000450a:	8a2a                	mv	s4,a0
    8000450c:	b7e5                	j	800044f4 <namex+0x42>
      iunlockput(ip);
    8000450e:	8552                	mv	a0,s4
    80004510:	00000097          	auipc	ra,0x0
    80004514:	c4c080e7          	jalr	-948(ra) # 8000415c <iunlockput>
      return 0;
    80004518:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000451a:	8552                	mv	a0,s4
    8000451c:	60e6                	ld	ra,88(sp)
    8000451e:	6446                	ld	s0,80(sp)
    80004520:	64a6                	ld	s1,72(sp)
    80004522:	6906                	ld	s2,64(sp)
    80004524:	79e2                	ld	s3,56(sp)
    80004526:	7a42                	ld	s4,48(sp)
    80004528:	7aa2                	ld	s5,40(sp)
    8000452a:	7b02                	ld	s6,32(sp)
    8000452c:	6be2                	ld	s7,24(sp)
    8000452e:	6c42                	ld	s8,16(sp)
    80004530:	6ca2                	ld	s9,8(sp)
    80004532:	6125                	addi	sp,sp,96
    80004534:	8082                	ret
      iunlock(ip);
    80004536:	8552                	mv	a0,s4
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	a84080e7          	jalr	-1404(ra) # 80003fbc <iunlock>
      return ip;
    80004540:	bfe9                	j	8000451a <namex+0x68>
      iunlockput(ip);
    80004542:	8552                	mv	a0,s4
    80004544:	00000097          	auipc	ra,0x0
    80004548:	c18080e7          	jalr	-1000(ra) # 8000415c <iunlockput>
      return 0;
    8000454c:	8a4e                	mv	s4,s3
    8000454e:	b7f1                	j	8000451a <namex+0x68>
  len = path - s;
    80004550:	40998633          	sub	a2,s3,s1
    80004554:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004558:	099c5863          	bge	s8,s9,800045e8 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000455c:	4639                	li	a2,14
    8000455e:	85a6                	mv	a1,s1
    80004560:	8556                	mv	a0,s5
    80004562:	ffffd097          	auipc	ra,0xffffd
    80004566:	82e080e7          	jalr	-2002(ra) # 80000d90 <memmove>
    8000456a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000456c:	0004c783          	lbu	a5,0(s1)
    80004570:	01279763          	bne	a5,s2,8000457e <namex+0xcc>
    path++;
    80004574:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004576:	0004c783          	lbu	a5,0(s1)
    8000457a:	ff278de3          	beq	a5,s2,80004574 <namex+0xc2>
    ilock(ip);
    8000457e:	8552                	mv	a0,s4
    80004580:	00000097          	auipc	ra,0x0
    80004584:	976080e7          	jalr	-1674(ra) # 80003ef6 <ilock>
    if(ip->type != T_DIR){
    80004588:	044a1783          	lh	a5,68(s4)
    8000458c:	f97791e3          	bne	a5,s7,8000450e <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004590:	000b0563          	beqz	s6,8000459a <namex+0xe8>
    80004594:	0004c783          	lbu	a5,0(s1)
    80004598:	dfd9                	beqz	a5,80004536 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000459a:	4601                	li	a2,0
    8000459c:	85d6                	mv	a1,s5
    8000459e:	8552                	mv	a0,s4
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	e62080e7          	jalr	-414(ra) # 80004402 <dirlookup>
    800045a8:	89aa                	mv	s3,a0
    800045aa:	dd41                	beqz	a0,80004542 <namex+0x90>
    iunlockput(ip);
    800045ac:	8552                	mv	a0,s4
    800045ae:	00000097          	auipc	ra,0x0
    800045b2:	bae080e7          	jalr	-1106(ra) # 8000415c <iunlockput>
    ip = next;
    800045b6:	8a4e                	mv	s4,s3
  while(*path == '/')
    800045b8:	0004c783          	lbu	a5,0(s1)
    800045bc:	01279763          	bne	a5,s2,800045ca <namex+0x118>
    path++;
    800045c0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045c2:	0004c783          	lbu	a5,0(s1)
    800045c6:	ff278de3          	beq	a5,s2,800045c0 <namex+0x10e>
  if(*path == 0)
    800045ca:	cb9d                	beqz	a5,80004600 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800045cc:	0004c783          	lbu	a5,0(s1)
    800045d0:	89a6                	mv	s3,s1
  len = path - s;
    800045d2:	4c81                	li	s9,0
    800045d4:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800045d6:	01278963          	beq	a5,s2,800045e8 <namex+0x136>
    800045da:	dbbd                	beqz	a5,80004550 <namex+0x9e>
    path++;
    800045dc:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800045de:	0009c783          	lbu	a5,0(s3)
    800045e2:	ff279ce3          	bne	a5,s2,800045da <namex+0x128>
    800045e6:	b7ad                	j	80004550 <namex+0x9e>
    memmove(name, s, len);
    800045e8:	2601                	sext.w	a2,a2
    800045ea:	85a6                	mv	a1,s1
    800045ec:	8556                	mv	a0,s5
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	7a2080e7          	jalr	1954(ra) # 80000d90 <memmove>
    name[len] = 0;
    800045f6:	9cd6                	add	s9,s9,s5
    800045f8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045fc:	84ce                	mv	s1,s3
    800045fe:	b7bd                	j	8000456c <namex+0xba>
  if(nameiparent){
    80004600:	f00b0de3          	beqz	s6,8000451a <namex+0x68>
    iput(ip);
    80004604:	8552                	mv	a0,s4
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	aae080e7          	jalr	-1362(ra) # 800040b4 <iput>
    return 0;
    8000460e:	4a01                	li	s4,0
    80004610:	b729                	j	8000451a <namex+0x68>

0000000080004612 <dirlink>:
{
    80004612:	7139                	addi	sp,sp,-64
    80004614:	fc06                	sd	ra,56(sp)
    80004616:	f822                	sd	s0,48(sp)
    80004618:	f04a                	sd	s2,32(sp)
    8000461a:	ec4e                	sd	s3,24(sp)
    8000461c:	e852                	sd	s4,16(sp)
    8000461e:	0080                	addi	s0,sp,64
    80004620:	892a                	mv	s2,a0
    80004622:	8a2e                	mv	s4,a1
    80004624:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004626:	4601                	li	a2,0
    80004628:	00000097          	auipc	ra,0x0
    8000462c:	dda080e7          	jalr	-550(ra) # 80004402 <dirlookup>
    80004630:	ed25                	bnez	a0,800046a8 <dirlink+0x96>
    80004632:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004634:	04c92483          	lw	s1,76(s2)
    80004638:	c49d                	beqz	s1,80004666 <dirlink+0x54>
    8000463a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000463c:	4741                	li	a4,16
    8000463e:	86a6                	mv	a3,s1
    80004640:	fc040613          	addi	a2,s0,-64
    80004644:	4581                	li	a1,0
    80004646:	854a                	mv	a0,s2
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	b66080e7          	jalr	-1178(ra) # 800041ae <readi>
    80004650:	47c1                	li	a5,16
    80004652:	06f51163          	bne	a0,a5,800046b4 <dirlink+0xa2>
    if(de.inum == 0)
    80004656:	fc045783          	lhu	a5,-64(s0)
    8000465a:	c791                	beqz	a5,80004666 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000465c:	24c1                	addiw	s1,s1,16
    8000465e:	04c92783          	lw	a5,76(s2)
    80004662:	fcf4ede3          	bltu	s1,a5,8000463c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004666:	4639                	li	a2,14
    80004668:	85d2                	mv	a1,s4
    8000466a:	fc240513          	addi	a0,s0,-62
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	7cc080e7          	jalr	1996(ra) # 80000e3a <strncpy>
  de.inum = inum;
    80004676:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000467a:	4741                	li	a4,16
    8000467c:	86a6                	mv	a3,s1
    8000467e:	fc040613          	addi	a2,s0,-64
    80004682:	4581                	li	a1,0
    80004684:	854a                	mv	a0,s2
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	c38080e7          	jalr	-968(ra) # 800042be <writei>
    8000468e:	1541                	addi	a0,a0,-16
    80004690:	00a03533          	snez	a0,a0
    80004694:	40a00533          	neg	a0,a0
    80004698:	74a2                	ld	s1,40(sp)
}
    8000469a:	70e2                	ld	ra,56(sp)
    8000469c:	7442                	ld	s0,48(sp)
    8000469e:	7902                	ld	s2,32(sp)
    800046a0:	69e2                	ld	s3,24(sp)
    800046a2:	6a42                	ld	s4,16(sp)
    800046a4:	6121                	addi	sp,sp,64
    800046a6:	8082                	ret
    iput(ip);
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	a0c080e7          	jalr	-1524(ra) # 800040b4 <iput>
    return -1;
    800046b0:	557d                	li	a0,-1
    800046b2:	b7e5                	j	8000469a <dirlink+0x88>
      panic("dirlink read");
    800046b4:	00004517          	auipc	a0,0x4
    800046b8:	e4c50513          	addi	a0,a0,-436 # 80008500 <etext+0x500>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	ea4080e7          	jalr	-348(ra) # 80000560 <panic>

00000000800046c4 <namei>:

struct inode*
namei(char *path)
{
    800046c4:	1101                	addi	sp,sp,-32
    800046c6:	ec06                	sd	ra,24(sp)
    800046c8:	e822                	sd	s0,16(sp)
    800046ca:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046cc:	fe040613          	addi	a2,s0,-32
    800046d0:	4581                	li	a1,0
    800046d2:	00000097          	auipc	ra,0x0
    800046d6:	de0080e7          	jalr	-544(ra) # 800044b2 <namex>
}
    800046da:	60e2                	ld	ra,24(sp)
    800046dc:	6442                	ld	s0,16(sp)
    800046de:	6105                	addi	sp,sp,32
    800046e0:	8082                	ret

00000000800046e2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046e2:	1141                	addi	sp,sp,-16
    800046e4:	e406                	sd	ra,8(sp)
    800046e6:	e022                	sd	s0,0(sp)
    800046e8:	0800                	addi	s0,sp,16
    800046ea:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046ec:	4585                	li	a1,1
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	dc4080e7          	jalr	-572(ra) # 800044b2 <namex>
}
    800046f6:	60a2                	ld	ra,8(sp)
    800046f8:	6402                	ld	s0,0(sp)
    800046fa:	0141                	addi	sp,sp,16
    800046fc:	8082                	ret

00000000800046fe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046fe:	1101                	addi	sp,sp,-32
    80004700:	ec06                	sd	ra,24(sp)
    80004702:	e822                	sd	s0,16(sp)
    80004704:	e426                	sd	s1,8(sp)
    80004706:	e04a                	sd	s2,0(sp)
    80004708:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000470a:	00027917          	auipc	s2,0x27
    8000470e:	15690913          	addi	s2,s2,342 # 8002b860 <log>
    80004712:	01892583          	lw	a1,24(s2)
    80004716:	02892503          	lw	a0,40(s2)
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	fa8080e7          	jalr	-88(ra) # 800036c2 <bread>
    80004722:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004724:	02c92603          	lw	a2,44(s2)
    80004728:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000472a:	00c05f63          	blez	a2,80004748 <write_head+0x4a>
    8000472e:	00027717          	auipc	a4,0x27
    80004732:	16270713          	addi	a4,a4,354 # 8002b890 <log+0x30>
    80004736:	87aa                	mv	a5,a0
    80004738:	060a                	slli	a2,a2,0x2
    8000473a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000473c:	4314                	lw	a3,0(a4)
    8000473e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004740:	0711                	addi	a4,a4,4
    80004742:	0791                	addi	a5,a5,4
    80004744:	fec79ce3          	bne	a5,a2,8000473c <write_head+0x3e>
  }
  bwrite(buf);
    80004748:	8526                	mv	a0,s1
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	06a080e7          	jalr	106(ra) # 800037b4 <bwrite>
  brelse(buf);
    80004752:	8526                	mv	a0,s1
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	09e080e7          	jalr	158(ra) # 800037f2 <brelse>
}
    8000475c:	60e2                	ld	ra,24(sp)
    8000475e:	6442                	ld	s0,16(sp)
    80004760:	64a2                	ld	s1,8(sp)
    80004762:	6902                	ld	s2,0(sp)
    80004764:	6105                	addi	sp,sp,32
    80004766:	8082                	ret

0000000080004768 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004768:	00027797          	auipc	a5,0x27
    8000476c:	1247a783          	lw	a5,292(a5) # 8002b88c <log+0x2c>
    80004770:	0af05d63          	blez	a5,8000482a <install_trans+0xc2>
{
    80004774:	7139                	addi	sp,sp,-64
    80004776:	fc06                	sd	ra,56(sp)
    80004778:	f822                	sd	s0,48(sp)
    8000477a:	f426                	sd	s1,40(sp)
    8000477c:	f04a                	sd	s2,32(sp)
    8000477e:	ec4e                	sd	s3,24(sp)
    80004780:	e852                	sd	s4,16(sp)
    80004782:	e456                	sd	s5,8(sp)
    80004784:	e05a                	sd	s6,0(sp)
    80004786:	0080                	addi	s0,sp,64
    80004788:	8b2a                	mv	s6,a0
    8000478a:	00027a97          	auipc	s5,0x27
    8000478e:	106a8a93          	addi	s5,s5,262 # 8002b890 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004792:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004794:	00027997          	auipc	s3,0x27
    80004798:	0cc98993          	addi	s3,s3,204 # 8002b860 <log>
    8000479c:	a00d                	j	800047be <install_trans+0x56>
    brelse(lbuf);
    8000479e:	854a                	mv	a0,s2
    800047a0:	fffff097          	auipc	ra,0xfffff
    800047a4:	052080e7          	jalr	82(ra) # 800037f2 <brelse>
    brelse(dbuf);
    800047a8:	8526                	mv	a0,s1
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	048080e7          	jalr	72(ra) # 800037f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047b2:	2a05                	addiw	s4,s4,1
    800047b4:	0a91                	addi	s5,s5,4
    800047b6:	02c9a783          	lw	a5,44(s3)
    800047ba:	04fa5e63          	bge	s4,a5,80004816 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047be:	0189a583          	lw	a1,24(s3)
    800047c2:	014585bb          	addw	a1,a1,s4
    800047c6:	2585                	addiw	a1,a1,1
    800047c8:	0289a503          	lw	a0,40(s3)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	ef6080e7          	jalr	-266(ra) # 800036c2 <bread>
    800047d4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047d6:	000aa583          	lw	a1,0(s5)
    800047da:	0289a503          	lw	a0,40(s3)
    800047de:	fffff097          	auipc	ra,0xfffff
    800047e2:	ee4080e7          	jalr	-284(ra) # 800036c2 <bread>
    800047e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047e8:	40000613          	li	a2,1024
    800047ec:	05890593          	addi	a1,s2,88
    800047f0:	05850513          	addi	a0,a0,88
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	59c080e7          	jalr	1436(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    800047fc:	8526                	mv	a0,s1
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	fb6080e7          	jalr	-74(ra) # 800037b4 <bwrite>
    if(recovering == 0)
    80004806:	f80b1ce3          	bnez	s6,8000479e <install_trans+0x36>
      bunpin(dbuf);
    8000480a:	8526                	mv	a0,s1
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	0be080e7          	jalr	190(ra) # 800038ca <bunpin>
    80004814:	b769                	j	8000479e <install_trans+0x36>
}
    80004816:	70e2                	ld	ra,56(sp)
    80004818:	7442                	ld	s0,48(sp)
    8000481a:	74a2                	ld	s1,40(sp)
    8000481c:	7902                	ld	s2,32(sp)
    8000481e:	69e2                	ld	s3,24(sp)
    80004820:	6a42                	ld	s4,16(sp)
    80004822:	6aa2                	ld	s5,8(sp)
    80004824:	6b02                	ld	s6,0(sp)
    80004826:	6121                	addi	sp,sp,64
    80004828:	8082                	ret
    8000482a:	8082                	ret

000000008000482c <initlog>:
{
    8000482c:	7179                	addi	sp,sp,-48
    8000482e:	f406                	sd	ra,40(sp)
    80004830:	f022                	sd	s0,32(sp)
    80004832:	ec26                	sd	s1,24(sp)
    80004834:	e84a                	sd	s2,16(sp)
    80004836:	e44e                	sd	s3,8(sp)
    80004838:	1800                	addi	s0,sp,48
    8000483a:	892a                	mv	s2,a0
    8000483c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000483e:	00027497          	auipc	s1,0x27
    80004842:	02248493          	addi	s1,s1,34 # 8002b860 <log>
    80004846:	00004597          	auipc	a1,0x4
    8000484a:	cca58593          	addi	a1,a1,-822 # 80008510 <etext+0x510>
    8000484e:	8526                	mv	a0,s1
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	358080e7          	jalr	856(ra) # 80000ba8 <initlock>
  log.start = sb->logstart;
    80004858:	0149a583          	lw	a1,20(s3)
    8000485c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000485e:	0109a783          	lw	a5,16(s3)
    80004862:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004864:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004868:	854a                	mv	a0,s2
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	e58080e7          	jalr	-424(ra) # 800036c2 <bread>
  log.lh.n = lh->n;
    80004872:	4d30                	lw	a2,88(a0)
    80004874:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004876:	00c05f63          	blez	a2,80004894 <initlog+0x68>
    8000487a:	87aa                	mv	a5,a0
    8000487c:	00027717          	auipc	a4,0x27
    80004880:	01470713          	addi	a4,a4,20 # 8002b890 <log+0x30>
    80004884:	060a                	slli	a2,a2,0x2
    80004886:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004888:	4ff4                	lw	a3,92(a5)
    8000488a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000488c:	0791                	addi	a5,a5,4
    8000488e:	0711                	addi	a4,a4,4
    80004890:	fec79ce3          	bne	a5,a2,80004888 <initlog+0x5c>
  brelse(buf);
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	f5e080e7          	jalr	-162(ra) # 800037f2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000489c:	4505                	li	a0,1
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	eca080e7          	jalr	-310(ra) # 80004768 <install_trans>
  log.lh.n = 0;
    800048a6:	00027797          	auipc	a5,0x27
    800048aa:	fe07a323          	sw	zero,-26(a5) # 8002b88c <log+0x2c>
  write_head(); // clear the log
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	e50080e7          	jalr	-432(ra) # 800046fe <write_head>
}
    800048b6:	70a2                	ld	ra,40(sp)
    800048b8:	7402                	ld	s0,32(sp)
    800048ba:	64e2                	ld	s1,24(sp)
    800048bc:	6942                	ld	s2,16(sp)
    800048be:	69a2                	ld	s3,8(sp)
    800048c0:	6145                	addi	sp,sp,48
    800048c2:	8082                	ret

00000000800048c4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048c4:	1101                	addi	sp,sp,-32
    800048c6:	ec06                	sd	ra,24(sp)
    800048c8:	e822                	sd	s0,16(sp)
    800048ca:	e426                	sd	s1,8(sp)
    800048cc:	e04a                	sd	s2,0(sp)
    800048ce:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048d0:	00027517          	auipc	a0,0x27
    800048d4:	f9050513          	addi	a0,a0,-112 # 8002b860 <log>
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	360080e7          	jalr	864(ra) # 80000c38 <acquire>
  while(1){
    if(log.committing){
    800048e0:	00027497          	auipc	s1,0x27
    800048e4:	f8048493          	addi	s1,s1,-128 # 8002b860 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048e8:	4979                	li	s2,30
    800048ea:	a039                	j	800048f8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800048ec:	85a6                	mv	a1,s1
    800048ee:	8526                	mv	a0,s1
    800048f0:	ffffe097          	auipc	ra,0xffffe
    800048f4:	bf4080e7          	jalr	-1036(ra) # 800024e4 <sleep>
    if(log.committing){
    800048f8:	50dc                	lw	a5,36(s1)
    800048fa:	fbed                	bnez	a5,800048ec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048fc:	5098                	lw	a4,32(s1)
    800048fe:	2705                	addiw	a4,a4,1
    80004900:	0027179b          	slliw	a5,a4,0x2
    80004904:	9fb9                	addw	a5,a5,a4
    80004906:	0017979b          	slliw	a5,a5,0x1
    8000490a:	54d4                	lw	a3,44(s1)
    8000490c:	9fb5                	addw	a5,a5,a3
    8000490e:	00f95963          	bge	s2,a5,80004920 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004912:	85a6                	mv	a1,s1
    80004914:	8526                	mv	a0,s1
    80004916:	ffffe097          	auipc	ra,0xffffe
    8000491a:	bce080e7          	jalr	-1074(ra) # 800024e4 <sleep>
    8000491e:	bfe9                	j	800048f8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004920:	00027517          	auipc	a0,0x27
    80004924:	f4050513          	addi	a0,a0,-192 # 8002b860 <log>
    80004928:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	3c2080e7          	jalr	962(ra) # 80000cec <release>
      break;
    }
  }
}
    80004932:	60e2                	ld	ra,24(sp)
    80004934:	6442                	ld	s0,16(sp)
    80004936:	64a2                	ld	s1,8(sp)
    80004938:	6902                	ld	s2,0(sp)
    8000493a:	6105                	addi	sp,sp,32
    8000493c:	8082                	ret

000000008000493e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000493e:	7139                	addi	sp,sp,-64
    80004940:	fc06                	sd	ra,56(sp)
    80004942:	f822                	sd	s0,48(sp)
    80004944:	f426                	sd	s1,40(sp)
    80004946:	f04a                	sd	s2,32(sp)
    80004948:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000494a:	00027497          	auipc	s1,0x27
    8000494e:	f1648493          	addi	s1,s1,-234 # 8002b860 <log>
    80004952:	8526                	mv	a0,s1
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	2e4080e7          	jalr	740(ra) # 80000c38 <acquire>
  log.outstanding -= 1;
    8000495c:	509c                	lw	a5,32(s1)
    8000495e:	37fd                	addiw	a5,a5,-1
    80004960:	0007891b          	sext.w	s2,a5
    80004964:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004966:	50dc                	lw	a5,36(s1)
    80004968:	e7b9                	bnez	a5,800049b6 <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    8000496a:	06091163          	bnez	s2,800049cc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000496e:	00027497          	auipc	s1,0x27
    80004972:	ef248493          	addi	s1,s1,-270 # 8002b860 <log>
    80004976:	4785                	li	a5,1
    80004978:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000497a:	8526                	mv	a0,s1
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	370080e7          	jalr	880(ra) # 80000cec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004984:	54dc                	lw	a5,44(s1)
    80004986:	06f04763          	bgtz	a5,800049f4 <end_op+0xb6>
    acquire(&log.lock);
    8000498a:	00027497          	auipc	s1,0x27
    8000498e:	ed648493          	addi	s1,s1,-298 # 8002b860 <log>
    80004992:	8526                	mv	a0,s1
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	2a4080e7          	jalr	676(ra) # 80000c38 <acquire>
    log.committing = 0;
    8000499c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049a0:	8526                	mv	a0,s1
    800049a2:	ffffe097          	auipc	ra,0xffffe
    800049a6:	ba6080e7          	jalr	-1114(ra) # 80002548 <wakeup>
    release(&log.lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	340080e7          	jalr	832(ra) # 80000cec <release>
}
    800049b4:	a815                	j	800049e8 <end_op+0xaa>
    800049b6:	ec4e                	sd	s3,24(sp)
    800049b8:	e852                	sd	s4,16(sp)
    800049ba:	e456                	sd	s5,8(sp)
    panic("log.committing");
    800049bc:	00004517          	auipc	a0,0x4
    800049c0:	b5c50513          	addi	a0,a0,-1188 # 80008518 <etext+0x518>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	b9c080e7          	jalr	-1124(ra) # 80000560 <panic>
    wakeup(&log);
    800049cc:	00027497          	auipc	s1,0x27
    800049d0:	e9448493          	addi	s1,s1,-364 # 8002b860 <log>
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffe097          	auipc	ra,0xffffe
    800049da:	b72080e7          	jalr	-1166(ra) # 80002548 <wakeup>
  release(&log.lock);
    800049de:	8526                	mv	a0,s1
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	30c080e7          	jalr	780(ra) # 80000cec <release>
}
    800049e8:	70e2                	ld	ra,56(sp)
    800049ea:	7442                	ld	s0,48(sp)
    800049ec:	74a2                	ld	s1,40(sp)
    800049ee:	7902                	ld	s2,32(sp)
    800049f0:	6121                	addi	sp,sp,64
    800049f2:	8082                	ret
    800049f4:	ec4e                	sd	s3,24(sp)
    800049f6:	e852                	sd	s4,16(sp)
    800049f8:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    800049fa:	00027a97          	auipc	s5,0x27
    800049fe:	e96a8a93          	addi	s5,s5,-362 # 8002b890 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a02:	00027a17          	auipc	s4,0x27
    80004a06:	e5ea0a13          	addi	s4,s4,-418 # 8002b860 <log>
    80004a0a:	018a2583          	lw	a1,24(s4)
    80004a0e:	012585bb          	addw	a1,a1,s2
    80004a12:	2585                	addiw	a1,a1,1
    80004a14:	028a2503          	lw	a0,40(s4)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	caa080e7          	jalr	-854(ra) # 800036c2 <bread>
    80004a20:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a22:	000aa583          	lw	a1,0(s5)
    80004a26:	028a2503          	lw	a0,40(s4)
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	c98080e7          	jalr	-872(ra) # 800036c2 <bread>
    80004a32:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a34:	40000613          	li	a2,1024
    80004a38:	05850593          	addi	a1,a0,88
    80004a3c:	05848513          	addi	a0,s1,88
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	350080e7          	jalr	848(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    80004a48:	8526                	mv	a0,s1
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	d6a080e7          	jalr	-662(ra) # 800037b4 <bwrite>
    brelse(from);
    80004a52:	854e                	mv	a0,s3
    80004a54:	fffff097          	auipc	ra,0xfffff
    80004a58:	d9e080e7          	jalr	-610(ra) # 800037f2 <brelse>
    brelse(to);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	fffff097          	auipc	ra,0xfffff
    80004a62:	d94080e7          	jalr	-620(ra) # 800037f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a66:	2905                	addiw	s2,s2,1
    80004a68:	0a91                	addi	s5,s5,4
    80004a6a:	02ca2783          	lw	a5,44(s4)
    80004a6e:	f8f94ee3          	blt	s2,a5,80004a0a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	c8c080e7          	jalr	-884(ra) # 800046fe <write_head>
    install_trans(0); // Now install writes to home locations
    80004a7a:	4501                	li	a0,0
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	cec080e7          	jalr	-788(ra) # 80004768 <install_trans>
    log.lh.n = 0;
    80004a84:	00027797          	auipc	a5,0x27
    80004a88:	e007a423          	sw	zero,-504(a5) # 8002b88c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	c72080e7          	jalr	-910(ra) # 800046fe <write_head>
    80004a94:	69e2                	ld	s3,24(sp)
    80004a96:	6a42                	ld	s4,16(sp)
    80004a98:	6aa2                	ld	s5,8(sp)
    80004a9a:	bdc5                	j	8000498a <end_op+0x4c>

0000000080004a9c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a9c:	1101                	addi	sp,sp,-32
    80004a9e:	ec06                	sd	ra,24(sp)
    80004aa0:	e822                	sd	s0,16(sp)
    80004aa2:	e426                	sd	s1,8(sp)
    80004aa4:	e04a                	sd	s2,0(sp)
    80004aa6:	1000                	addi	s0,sp,32
    80004aa8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004aaa:	00027917          	auipc	s2,0x27
    80004aae:	db690913          	addi	s2,s2,-586 # 8002b860 <log>
    80004ab2:	854a                	mv	a0,s2
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	184080e7          	jalr	388(ra) # 80000c38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004abc:	02c92603          	lw	a2,44(s2)
    80004ac0:	47f5                	li	a5,29
    80004ac2:	06c7c563          	blt	a5,a2,80004b2c <log_write+0x90>
    80004ac6:	00027797          	auipc	a5,0x27
    80004aca:	db67a783          	lw	a5,-586(a5) # 8002b87c <log+0x1c>
    80004ace:	37fd                	addiw	a5,a5,-1
    80004ad0:	04f65e63          	bge	a2,a5,80004b2c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ad4:	00027797          	auipc	a5,0x27
    80004ad8:	dac7a783          	lw	a5,-596(a5) # 8002b880 <log+0x20>
    80004adc:	06f05063          	blez	a5,80004b3c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ae0:	4781                	li	a5,0
    80004ae2:	06c05563          	blez	a2,80004b4c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ae6:	44cc                	lw	a1,12(s1)
    80004ae8:	00027717          	auipc	a4,0x27
    80004aec:	da870713          	addi	a4,a4,-600 # 8002b890 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004af0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004af2:	4314                	lw	a3,0(a4)
    80004af4:	04b68c63          	beq	a3,a1,80004b4c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004af8:	2785                	addiw	a5,a5,1
    80004afa:	0711                	addi	a4,a4,4
    80004afc:	fef61be3          	bne	a2,a5,80004af2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b00:	0621                	addi	a2,a2,8
    80004b02:	060a                	slli	a2,a2,0x2
    80004b04:	00027797          	auipc	a5,0x27
    80004b08:	d5c78793          	addi	a5,a5,-676 # 8002b860 <log>
    80004b0c:	97b2                	add	a5,a5,a2
    80004b0e:	44d8                	lw	a4,12(s1)
    80004b10:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b12:	8526                	mv	a0,s1
    80004b14:	fffff097          	auipc	ra,0xfffff
    80004b18:	d7a080e7          	jalr	-646(ra) # 8000388e <bpin>
    log.lh.n++;
    80004b1c:	00027717          	auipc	a4,0x27
    80004b20:	d4470713          	addi	a4,a4,-700 # 8002b860 <log>
    80004b24:	575c                	lw	a5,44(a4)
    80004b26:	2785                	addiw	a5,a5,1
    80004b28:	d75c                	sw	a5,44(a4)
    80004b2a:	a82d                	j	80004b64 <log_write+0xc8>
    panic("too big a transaction");
    80004b2c:	00004517          	auipc	a0,0x4
    80004b30:	9fc50513          	addi	a0,a0,-1540 # 80008528 <etext+0x528>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	a2c080e7          	jalr	-1492(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    80004b3c:	00004517          	auipc	a0,0x4
    80004b40:	a0450513          	addi	a0,a0,-1532 # 80008540 <etext+0x540>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	a1c080e7          	jalr	-1508(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    80004b4c:	00878693          	addi	a3,a5,8
    80004b50:	068a                	slli	a3,a3,0x2
    80004b52:	00027717          	auipc	a4,0x27
    80004b56:	d0e70713          	addi	a4,a4,-754 # 8002b860 <log>
    80004b5a:	9736                	add	a4,a4,a3
    80004b5c:	44d4                	lw	a3,12(s1)
    80004b5e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b60:	faf609e3          	beq	a2,a5,80004b12 <log_write+0x76>
  }
  release(&log.lock);
    80004b64:	00027517          	auipc	a0,0x27
    80004b68:	cfc50513          	addi	a0,a0,-772 # 8002b860 <log>
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	180080e7          	jalr	384(ra) # 80000cec <release>
}
    80004b74:	60e2                	ld	ra,24(sp)
    80004b76:	6442                	ld	s0,16(sp)
    80004b78:	64a2                	ld	s1,8(sp)
    80004b7a:	6902                	ld	s2,0(sp)
    80004b7c:	6105                	addi	sp,sp,32
    80004b7e:	8082                	ret

0000000080004b80 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b80:	1101                	addi	sp,sp,-32
    80004b82:	ec06                	sd	ra,24(sp)
    80004b84:	e822                	sd	s0,16(sp)
    80004b86:	e426                	sd	s1,8(sp)
    80004b88:	e04a                	sd	s2,0(sp)
    80004b8a:	1000                	addi	s0,sp,32
    80004b8c:	84aa                	mv	s1,a0
    80004b8e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b90:	00004597          	auipc	a1,0x4
    80004b94:	9d058593          	addi	a1,a1,-1584 # 80008560 <etext+0x560>
    80004b98:	0521                	addi	a0,a0,8
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	00e080e7          	jalr	14(ra) # 80000ba8 <initlock>
  lk->name = name;
    80004ba2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ba6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004baa:	0204a423          	sw	zero,40(s1)
}
    80004bae:	60e2                	ld	ra,24(sp)
    80004bb0:	6442                	ld	s0,16(sp)
    80004bb2:	64a2                	ld	s1,8(sp)
    80004bb4:	6902                	ld	s2,0(sp)
    80004bb6:	6105                	addi	sp,sp,32
    80004bb8:	8082                	ret

0000000080004bba <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004bba:	1101                	addi	sp,sp,-32
    80004bbc:	ec06                	sd	ra,24(sp)
    80004bbe:	e822                	sd	s0,16(sp)
    80004bc0:	e426                	sd	s1,8(sp)
    80004bc2:	e04a                	sd	s2,0(sp)
    80004bc4:	1000                	addi	s0,sp,32
    80004bc6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bc8:	00850913          	addi	s2,a0,8
    80004bcc:	854a                	mv	a0,s2
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	06a080e7          	jalr	106(ra) # 80000c38 <acquire>
  while (lk->locked) {
    80004bd6:	409c                	lw	a5,0(s1)
    80004bd8:	cb89                	beqz	a5,80004bea <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bda:	85ca                	mv	a1,s2
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffe097          	auipc	ra,0xffffe
    80004be2:	906080e7          	jalr	-1786(ra) # 800024e4 <sleep>
  while (lk->locked) {
    80004be6:	409c                	lw	a5,0(s1)
    80004be8:	fbed                	bnez	a5,80004bda <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bea:	4785                	li	a5,1
    80004bec:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	e8c080e7          	jalr	-372(ra) # 80001a7a <myproc>
    80004bf6:	591c                	lw	a5,48(a0)
    80004bf8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bfa:	854a                	mv	a0,s2
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	0f0080e7          	jalr	240(ra) # 80000cec <release>
}
    80004c04:	60e2                	ld	ra,24(sp)
    80004c06:	6442                	ld	s0,16(sp)
    80004c08:	64a2                	ld	s1,8(sp)
    80004c0a:	6902                	ld	s2,0(sp)
    80004c0c:	6105                	addi	sp,sp,32
    80004c0e:	8082                	ret

0000000080004c10 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c10:	1101                	addi	sp,sp,-32
    80004c12:	ec06                	sd	ra,24(sp)
    80004c14:	e822                	sd	s0,16(sp)
    80004c16:	e426                	sd	s1,8(sp)
    80004c18:	e04a                	sd	s2,0(sp)
    80004c1a:	1000                	addi	s0,sp,32
    80004c1c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c1e:	00850913          	addi	s2,a0,8
    80004c22:	854a                	mv	a0,s2
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	014080e7          	jalr	20(ra) # 80000c38 <acquire>
  lk->locked = 0;
    80004c2c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c30:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffe097          	auipc	ra,0xffffe
    80004c3a:	912080e7          	jalr	-1774(ra) # 80002548 <wakeup>
  release(&lk->lk);
    80004c3e:	854a                	mv	a0,s2
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	0ac080e7          	jalr	172(ra) # 80000cec <release>
}
    80004c48:	60e2                	ld	ra,24(sp)
    80004c4a:	6442                	ld	s0,16(sp)
    80004c4c:	64a2                	ld	s1,8(sp)
    80004c4e:	6902                	ld	s2,0(sp)
    80004c50:	6105                	addi	sp,sp,32
    80004c52:	8082                	ret

0000000080004c54 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c54:	7179                	addi	sp,sp,-48
    80004c56:	f406                	sd	ra,40(sp)
    80004c58:	f022                	sd	s0,32(sp)
    80004c5a:	ec26                	sd	s1,24(sp)
    80004c5c:	e84a                	sd	s2,16(sp)
    80004c5e:	1800                	addi	s0,sp,48
    80004c60:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c62:	00850913          	addi	s2,a0,8
    80004c66:	854a                	mv	a0,s2
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	fd0080e7          	jalr	-48(ra) # 80000c38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c70:	409c                	lw	a5,0(s1)
    80004c72:	ef91                	bnez	a5,80004c8e <holdingsleep+0x3a>
    80004c74:	4481                	li	s1,0
  release(&lk->lk);
    80004c76:	854a                	mv	a0,s2
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	074080e7          	jalr	116(ra) # 80000cec <release>
  return r;
}
    80004c80:	8526                	mv	a0,s1
    80004c82:	70a2                	ld	ra,40(sp)
    80004c84:	7402                	ld	s0,32(sp)
    80004c86:	64e2                	ld	s1,24(sp)
    80004c88:	6942                	ld	s2,16(sp)
    80004c8a:	6145                	addi	sp,sp,48
    80004c8c:	8082                	ret
    80004c8e:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c90:	0284a983          	lw	s3,40(s1)
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	de6080e7          	jalr	-538(ra) # 80001a7a <myproc>
    80004c9c:	5904                	lw	s1,48(a0)
    80004c9e:	413484b3          	sub	s1,s1,s3
    80004ca2:	0014b493          	seqz	s1,s1
    80004ca6:	69a2                	ld	s3,8(sp)
    80004ca8:	b7f9                	j	80004c76 <holdingsleep+0x22>

0000000080004caa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004caa:	1141                	addi	sp,sp,-16
    80004cac:	e406                	sd	ra,8(sp)
    80004cae:	e022                	sd	s0,0(sp)
    80004cb0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cb2:	00004597          	auipc	a1,0x4
    80004cb6:	8be58593          	addi	a1,a1,-1858 # 80008570 <etext+0x570>
    80004cba:	00027517          	auipc	a0,0x27
    80004cbe:	cee50513          	addi	a0,a0,-786 # 8002b9a8 <ftable>
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	ee6080e7          	jalr	-282(ra) # 80000ba8 <initlock>
}
    80004cca:	60a2                	ld	ra,8(sp)
    80004ccc:	6402                	ld	s0,0(sp)
    80004cce:	0141                	addi	sp,sp,16
    80004cd0:	8082                	ret

0000000080004cd2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cd2:	1101                	addi	sp,sp,-32
    80004cd4:	ec06                	sd	ra,24(sp)
    80004cd6:	e822                	sd	s0,16(sp)
    80004cd8:	e426                	sd	s1,8(sp)
    80004cda:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cdc:	00027517          	auipc	a0,0x27
    80004ce0:	ccc50513          	addi	a0,a0,-820 # 8002b9a8 <ftable>
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	f54080e7          	jalr	-172(ra) # 80000c38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cec:	00027497          	auipc	s1,0x27
    80004cf0:	cd448493          	addi	s1,s1,-812 # 8002b9c0 <ftable+0x18>
    80004cf4:	00028717          	auipc	a4,0x28
    80004cf8:	c6c70713          	addi	a4,a4,-916 # 8002c960 <disk>
    if(f->ref == 0){
    80004cfc:	40dc                	lw	a5,4(s1)
    80004cfe:	cf99                	beqz	a5,80004d1c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d00:	02848493          	addi	s1,s1,40
    80004d04:	fee49ce3          	bne	s1,a4,80004cfc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d08:	00027517          	auipc	a0,0x27
    80004d0c:	ca050513          	addi	a0,a0,-864 # 8002b9a8 <ftable>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	fdc080e7          	jalr	-36(ra) # 80000cec <release>
  return 0;
    80004d18:	4481                	li	s1,0
    80004d1a:	a819                	j	80004d30 <filealloc+0x5e>
      f->ref = 1;
    80004d1c:	4785                	li	a5,1
    80004d1e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d20:	00027517          	auipc	a0,0x27
    80004d24:	c8850513          	addi	a0,a0,-888 # 8002b9a8 <ftable>
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	fc4080e7          	jalr	-60(ra) # 80000cec <release>
}
    80004d30:	8526                	mv	a0,s1
    80004d32:	60e2                	ld	ra,24(sp)
    80004d34:	6442                	ld	s0,16(sp)
    80004d36:	64a2                	ld	s1,8(sp)
    80004d38:	6105                	addi	sp,sp,32
    80004d3a:	8082                	ret

0000000080004d3c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d3c:	1101                	addi	sp,sp,-32
    80004d3e:	ec06                	sd	ra,24(sp)
    80004d40:	e822                	sd	s0,16(sp)
    80004d42:	e426                	sd	s1,8(sp)
    80004d44:	1000                	addi	s0,sp,32
    80004d46:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d48:	00027517          	auipc	a0,0x27
    80004d4c:	c6050513          	addi	a0,a0,-928 # 8002b9a8 <ftable>
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	ee8080e7          	jalr	-280(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004d58:	40dc                	lw	a5,4(s1)
    80004d5a:	02f05263          	blez	a5,80004d7e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d5e:	2785                	addiw	a5,a5,1
    80004d60:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d62:	00027517          	auipc	a0,0x27
    80004d66:	c4650513          	addi	a0,a0,-954 # 8002b9a8 <ftable>
    80004d6a:	ffffc097          	auipc	ra,0xffffc
    80004d6e:	f82080e7          	jalr	-126(ra) # 80000cec <release>
  return f;
}
    80004d72:	8526                	mv	a0,s1
    80004d74:	60e2                	ld	ra,24(sp)
    80004d76:	6442                	ld	s0,16(sp)
    80004d78:	64a2                	ld	s1,8(sp)
    80004d7a:	6105                	addi	sp,sp,32
    80004d7c:	8082                	ret
    panic("filedup");
    80004d7e:	00003517          	auipc	a0,0x3
    80004d82:	7fa50513          	addi	a0,a0,2042 # 80008578 <etext+0x578>
    80004d86:	ffffb097          	auipc	ra,0xffffb
    80004d8a:	7da080e7          	jalr	2010(ra) # 80000560 <panic>

0000000080004d8e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d8e:	7139                	addi	sp,sp,-64
    80004d90:	fc06                	sd	ra,56(sp)
    80004d92:	f822                	sd	s0,48(sp)
    80004d94:	f426                	sd	s1,40(sp)
    80004d96:	0080                	addi	s0,sp,64
    80004d98:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d9a:	00027517          	auipc	a0,0x27
    80004d9e:	c0e50513          	addi	a0,a0,-1010 # 8002b9a8 <ftable>
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	e96080e7          	jalr	-362(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004daa:	40dc                	lw	a5,4(s1)
    80004dac:	04f05c63          	blez	a5,80004e04 <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80004db0:	37fd                	addiw	a5,a5,-1
    80004db2:	0007871b          	sext.w	a4,a5
    80004db6:	c0dc                	sw	a5,4(s1)
    80004db8:	06e04263          	bgtz	a4,80004e1c <fileclose+0x8e>
    80004dbc:	f04a                	sd	s2,32(sp)
    80004dbe:	ec4e                	sd	s3,24(sp)
    80004dc0:	e852                	sd	s4,16(sp)
    80004dc2:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004dc4:	0004a903          	lw	s2,0(s1)
    80004dc8:	0094ca83          	lbu	s5,9(s1)
    80004dcc:	0104ba03          	ld	s4,16(s1)
    80004dd0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004dd4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dd8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ddc:	00027517          	auipc	a0,0x27
    80004de0:	bcc50513          	addi	a0,a0,-1076 # 8002b9a8 <ftable>
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	f08080e7          	jalr	-248(ra) # 80000cec <release>

  if(ff.type == FD_PIPE){
    80004dec:	4785                	li	a5,1
    80004dee:	04f90463          	beq	s2,a5,80004e36 <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004df2:	3979                	addiw	s2,s2,-2
    80004df4:	4785                	li	a5,1
    80004df6:	0527fb63          	bgeu	a5,s2,80004e4c <fileclose+0xbe>
    80004dfa:	7902                	ld	s2,32(sp)
    80004dfc:	69e2                	ld	s3,24(sp)
    80004dfe:	6a42                	ld	s4,16(sp)
    80004e00:	6aa2                	ld	s5,8(sp)
    80004e02:	a02d                	j	80004e2c <fileclose+0x9e>
    80004e04:	f04a                	sd	s2,32(sp)
    80004e06:	ec4e                	sd	s3,24(sp)
    80004e08:	e852                	sd	s4,16(sp)
    80004e0a:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004e0c:	00003517          	auipc	a0,0x3
    80004e10:	77450513          	addi	a0,a0,1908 # 80008580 <etext+0x580>
    80004e14:	ffffb097          	auipc	ra,0xffffb
    80004e18:	74c080e7          	jalr	1868(ra) # 80000560 <panic>
    release(&ftable.lock);
    80004e1c:	00027517          	auipc	a0,0x27
    80004e20:	b8c50513          	addi	a0,a0,-1140 # 8002b9a8 <ftable>
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	ec8080e7          	jalr	-312(ra) # 80000cec <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004e2c:	70e2                	ld	ra,56(sp)
    80004e2e:	7442                	ld	s0,48(sp)
    80004e30:	74a2                	ld	s1,40(sp)
    80004e32:	6121                	addi	sp,sp,64
    80004e34:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e36:	85d6                	mv	a1,s5
    80004e38:	8552                	mv	a0,s4
    80004e3a:	00000097          	auipc	ra,0x0
    80004e3e:	3a2080e7          	jalr	930(ra) # 800051dc <pipeclose>
    80004e42:	7902                	ld	s2,32(sp)
    80004e44:	69e2                	ld	s3,24(sp)
    80004e46:	6a42                	ld	s4,16(sp)
    80004e48:	6aa2                	ld	s5,8(sp)
    80004e4a:	b7cd                	j	80004e2c <fileclose+0x9e>
    begin_op();
    80004e4c:	00000097          	auipc	ra,0x0
    80004e50:	a78080e7          	jalr	-1416(ra) # 800048c4 <begin_op>
    iput(ff.ip);
    80004e54:	854e                	mv	a0,s3
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	25e080e7          	jalr	606(ra) # 800040b4 <iput>
    end_op();
    80004e5e:	00000097          	auipc	ra,0x0
    80004e62:	ae0080e7          	jalr	-1312(ra) # 8000493e <end_op>
    80004e66:	7902                	ld	s2,32(sp)
    80004e68:	69e2                	ld	s3,24(sp)
    80004e6a:	6a42                	ld	s4,16(sp)
    80004e6c:	6aa2                	ld	s5,8(sp)
    80004e6e:	bf7d                	j	80004e2c <fileclose+0x9e>

0000000080004e70 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e70:	715d                	addi	sp,sp,-80
    80004e72:	e486                	sd	ra,72(sp)
    80004e74:	e0a2                	sd	s0,64(sp)
    80004e76:	fc26                	sd	s1,56(sp)
    80004e78:	f44e                	sd	s3,40(sp)
    80004e7a:	0880                	addi	s0,sp,80
    80004e7c:	84aa                	mv	s1,a0
    80004e7e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e80:	ffffd097          	auipc	ra,0xffffd
    80004e84:	bfa080e7          	jalr	-1030(ra) # 80001a7a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e88:	409c                	lw	a5,0(s1)
    80004e8a:	37f9                	addiw	a5,a5,-2
    80004e8c:	4705                	li	a4,1
    80004e8e:	04f76863          	bltu	a4,a5,80004ede <filestat+0x6e>
    80004e92:	f84a                	sd	s2,48(sp)
    80004e94:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e96:	6c88                	ld	a0,24(s1)
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	05e080e7          	jalr	94(ra) # 80003ef6 <ilock>
    stati(f->ip, &st);
    80004ea0:	fb840593          	addi	a1,s0,-72
    80004ea4:	6c88                	ld	a0,24(s1)
    80004ea6:	fffff097          	auipc	ra,0xfffff
    80004eaa:	2de080e7          	jalr	734(ra) # 80004184 <stati>
    iunlock(f->ip);
    80004eae:	6c88                	ld	a0,24(s1)
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	10c080e7          	jalr	268(ra) # 80003fbc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004eb8:	46e1                	li	a3,24
    80004eba:	fb840613          	addi	a2,s0,-72
    80004ebe:	85ce                	mv	a1,s3
    80004ec0:	22893503          	ld	a0,552(s2)
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	81e080e7          	jalr	-2018(ra) # 800016e2 <copyout>
    80004ecc:	41f5551b          	sraiw	a0,a0,0x1f
    80004ed0:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004ed2:	60a6                	ld	ra,72(sp)
    80004ed4:	6406                	ld	s0,64(sp)
    80004ed6:	74e2                	ld	s1,56(sp)
    80004ed8:	79a2                	ld	s3,40(sp)
    80004eda:	6161                	addi	sp,sp,80
    80004edc:	8082                	ret
  return -1;
    80004ede:	557d                	li	a0,-1
    80004ee0:	bfcd                	j	80004ed2 <filestat+0x62>

0000000080004ee2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ee2:	7179                	addi	sp,sp,-48
    80004ee4:	f406                	sd	ra,40(sp)
    80004ee6:	f022                	sd	s0,32(sp)
    80004ee8:	e84a                	sd	s2,16(sp)
    80004eea:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004eec:	00854783          	lbu	a5,8(a0)
    80004ef0:	cbc5                	beqz	a5,80004fa0 <fileread+0xbe>
    80004ef2:	ec26                	sd	s1,24(sp)
    80004ef4:	e44e                	sd	s3,8(sp)
    80004ef6:	84aa                	mv	s1,a0
    80004ef8:	89ae                	mv	s3,a1
    80004efa:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004efc:	411c                	lw	a5,0(a0)
    80004efe:	4705                	li	a4,1
    80004f00:	04e78963          	beq	a5,a4,80004f52 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f04:	470d                	li	a4,3
    80004f06:	04e78f63          	beq	a5,a4,80004f64 <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f0a:	4709                	li	a4,2
    80004f0c:	08e79263          	bne	a5,a4,80004f90 <fileread+0xae>
    ilock(f->ip);
    80004f10:	6d08                	ld	a0,24(a0)
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	fe4080e7          	jalr	-28(ra) # 80003ef6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f1a:	874a                	mv	a4,s2
    80004f1c:	5094                	lw	a3,32(s1)
    80004f1e:	864e                	mv	a2,s3
    80004f20:	4585                	li	a1,1
    80004f22:	6c88                	ld	a0,24(s1)
    80004f24:	fffff097          	auipc	ra,0xfffff
    80004f28:	28a080e7          	jalr	650(ra) # 800041ae <readi>
    80004f2c:	892a                	mv	s2,a0
    80004f2e:	00a05563          	blez	a0,80004f38 <fileread+0x56>
      f->off += r;
    80004f32:	509c                	lw	a5,32(s1)
    80004f34:	9fa9                	addw	a5,a5,a0
    80004f36:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f38:	6c88                	ld	a0,24(s1)
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	082080e7          	jalr	130(ra) # 80003fbc <iunlock>
    80004f42:	64e2                	ld	s1,24(sp)
    80004f44:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    80004f46:	854a                	mv	a0,s2
    80004f48:	70a2                	ld	ra,40(sp)
    80004f4a:	7402                	ld	s0,32(sp)
    80004f4c:	6942                	ld	s2,16(sp)
    80004f4e:	6145                	addi	sp,sp,48
    80004f50:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f52:	6908                	ld	a0,16(a0)
    80004f54:	00000097          	auipc	ra,0x0
    80004f58:	400080e7          	jalr	1024(ra) # 80005354 <piperead>
    80004f5c:	892a                	mv	s2,a0
    80004f5e:	64e2                	ld	s1,24(sp)
    80004f60:	69a2                	ld	s3,8(sp)
    80004f62:	b7d5                	j	80004f46 <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f64:	02451783          	lh	a5,36(a0)
    80004f68:	03079693          	slli	a3,a5,0x30
    80004f6c:	92c1                	srli	a3,a3,0x30
    80004f6e:	4725                	li	a4,9
    80004f70:	02d76a63          	bltu	a4,a3,80004fa4 <fileread+0xc2>
    80004f74:	0792                	slli	a5,a5,0x4
    80004f76:	00027717          	auipc	a4,0x27
    80004f7a:	99270713          	addi	a4,a4,-1646 # 8002b908 <devsw>
    80004f7e:	97ba                	add	a5,a5,a4
    80004f80:	639c                	ld	a5,0(a5)
    80004f82:	c78d                	beqz	a5,80004fac <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    80004f84:	4505                	li	a0,1
    80004f86:	9782                	jalr	a5
    80004f88:	892a                	mv	s2,a0
    80004f8a:	64e2                	ld	s1,24(sp)
    80004f8c:	69a2                	ld	s3,8(sp)
    80004f8e:	bf65                	j	80004f46 <fileread+0x64>
    panic("fileread");
    80004f90:	00003517          	auipc	a0,0x3
    80004f94:	60050513          	addi	a0,a0,1536 # 80008590 <etext+0x590>
    80004f98:	ffffb097          	auipc	ra,0xffffb
    80004f9c:	5c8080e7          	jalr	1480(ra) # 80000560 <panic>
    return -1;
    80004fa0:	597d                	li	s2,-1
    80004fa2:	b755                	j	80004f46 <fileread+0x64>
      return -1;
    80004fa4:	597d                	li	s2,-1
    80004fa6:	64e2                	ld	s1,24(sp)
    80004fa8:	69a2                	ld	s3,8(sp)
    80004faa:	bf71                	j	80004f46 <fileread+0x64>
    80004fac:	597d                	li	s2,-1
    80004fae:	64e2                	ld	s1,24(sp)
    80004fb0:	69a2                	ld	s3,8(sp)
    80004fb2:	bf51                	j	80004f46 <fileread+0x64>

0000000080004fb4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004fb4:	00954783          	lbu	a5,9(a0)
    80004fb8:	12078963          	beqz	a5,800050ea <filewrite+0x136>
{
    80004fbc:	715d                	addi	sp,sp,-80
    80004fbe:	e486                	sd	ra,72(sp)
    80004fc0:	e0a2                	sd	s0,64(sp)
    80004fc2:	f84a                	sd	s2,48(sp)
    80004fc4:	f052                	sd	s4,32(sp)
    80004fc6:	e85a                	sd	s6,16(sp)
    80004fc8:	0880                	addi	s0,sp,80
    80004fca:	892a                	mv	s2,a0
    80004fcc:	8b2e                	mv	s6,a1
    80004fce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fd0:	411c                	lw	a5,0(a0)
    80004fd2:	4705                	li	a4,1
    80004fd4:	02e78763          	beq	a5,a4,80005002 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fd8:	470d                	li	a4,3
    80004fda:	02e78a63          	beq	a5,a4,8000500e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fde:	4709                	li	a4,2
    80004fe0:	0ee79863          	bne	a5,a4,800050d0 <filewrite+0x11c>
    80004fe4:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fe6:	0cc05463          	blez	a2,800050ae <filewrite+0xfa>
    80004fea:	fc26                	sd	s1,56(sp)
    80004fec:	ec56                	sd	s5,24(sp)
    80004fee:	e45e                	sd	s7,8(sp)
    80004ff0:	e062                	sd	s8,0(sp)
    int i = 0;
    80004ff2:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004ff4:	6b85                	lui	s7,0x1
    80004ff6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004ffa:	6c05                	lui	s8,0x1
    80004ffc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005000:	a851                	j	80005094 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80005002:	6908                	ld	a0,16(a0)
    80005004:	00000097          	auipc	ra,0x0
    80005008:	248080e7          	jalr	584(ra) # 8000524c <pipewrite>
    8000500c:	a85d                	j	800050c2 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000500e:	02451783          	lh	a5,36(a0)
    80005012:	03079693          	slli	a3,a5,0x30
    80005016:	92c1                	srli	a3,a3,0x30
    80005018:	4725                	li	a4,9
    8000501a:	0cd76a63          	bltu	a4,a3,800050ee <filewrite+0x13a>
    8000501e:	0792                	slli	a5,a5,0x4
    80005020:	00027717          	auipc	a4,0x27
    80005024:	8e870713          	addi	a4,a4,-1816 # 8002b908 <devsw>
    80005028:	97ba                	add	a5,a5,a4
    8000502a:	679c                	ld	a5,8(a5)
    8000502c:	c3f9                	beqz	a5,800050f2 <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    8000502e:	4505                	li	a0,1
    80005030:	9782                	jalr	a5
    80005032:	a841                	j	800050c2 <filewrite+0x10e>
      if(n1 > max)
    80005034:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80005038:	00000097          	auipc	ra,0x0
    8000503c:	88c080e7          	jalr	-1908(ra) # 800048c4 <begin_op>
      ilock(f->ip);
    80005040:	01893503          	ld	a0,24(s2)
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	eb2080e7          	jalr	-334(ra) # 80003ef6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000504c:	8756                	mv	a4,s5
    8000504e:	02092683          	lw	a3,32(s2)
    80005052:	01698633          	add	a2,s3,s6
    80005056:	4585                	li	a1,1
    80005058:	01893503          	ld	a0,24(s2)
    8000505c:	fffff097          	auipc	ra,0xfffff
    80005060:	262080e7          	jalr	610(ra) # 800042be <writei>
    80005064:	84aa                	mv	s1,a0
    80005066:	00a05763          	blez	a0,80005074 <filewrite+0xc0>
        f->off += r;
    8000506a:	02092783          	lw	a5,32(s2)
    8000506e:	9fa9                	addw	a5,a5,a0
    80005070:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005074:	01893503          	ld	a0,24(s2)
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	f44080e7          	jalr	-188(ra) # 80003fbc <iunlock>
      end_op();
    80005080:	00000097          	auipc	ra,0x0
    80005084:	8be080e7          	jalr	-1858(ra) # 8000493e <end_op>

      if(r != n1){
    80005088:	029a9563          	bne	s5,s1,800050b2 <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    8000508c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005090:	0149da63          	bge	s3,s4,800050a4 <filewrite+0xf0>
      int n1 = n - i;
    80005094:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80005098:	0004879b          	sext.w	a5,s1
    8000509c:	f8fbdce3          	bge	s7,a5,80005034 <filewrite+0x80>
    800050a0:	84e2                	mv	s1,s8
    800050a2:	bf49                	j	80005034 <filewrite+0x80>
    800050a4:	74e2                	ld	s1,56(sp)
    800050a6:	6ae2                	ld	s5,24(sp)
    800050a8:	6ba2                	ld	s7,8(sp)
    800050aa:	6c02                	ld	s8,0(sp)
    800050ac:	a039                	j	800050ba <filewrite+0x106>
    int i = 0;
    800050ae:	4981                	li	s3,0
    800050b0:	a029                	j	800050ba <filewrite+0x106>
    800050b2:	74e2                	ld	s1,56(sp)
    800050b4:	6ae2                	ld	s5,24(sp)
    800050b6:	6ba2                	ld	s7,8(sp)
    800050b8:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800050ba:	033a1e63          	bne	s4,s3,800050f6 <filewrite+0x142>
    800050be:	8552                	mv	a0,s4
    800050c0:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050c2:	60a6                	ld	ra,72(sp)
    800050c4:	6406                	ld	s0,64(sp)
    800050c6:	7942                	ld	s2,48(sp)
    800050c8:	7a02                	ld	s4,32(sp)
    800050ca:	6b42                	ld	s6,16(sp)
    800050cc:	6161                	addi	sp,sp,80
    800050ce:	8082                	ret
    800050d0:	fc26                	sd	s1,56(sp)
    800050d2:	f44e                	sd	s3,40(sp)
    800050d4:	ec56                	sd	s5,24(sp)
    800050d6:	e45e                	sd	s7,8(sp)
    800050d8:	e062                	sd	s8,0(sp)
    panic("filewrite");
    800050da:	00003517          	auipc	a0,0x3
    800050de:	4c650513          	addi	a0,a0,1222 # 800085a0 <etext+0x5a0>
    800050e2:	ffffb097          	auipc	ra,0xffffb
    800050e6:	47e080e7          	jalr	1150(ra) # 80000560 <panic>
    return -1;
    800050ea:	557d                	li	a0,-1
}
    800050ec:	8082                	ret
      return -1;
    800050ee:	557d                	li	a0,-1
    800050f0:	bfc9                	j	800050c2 <filewrite+0x10e>
    800050f2:	557d                	li	a0,-1
    800050f4:	b7f9                	j	800050c2 <filewrite+0x10e>
    ret = (i == n ? n : -1);
    800050f6:	557d                	li	a0,-1
    800050f8:	79a2                	ld	s3,40(sp)
    800050fa:	b7e1                	j	800050c2 <filewrite+0x10e>

00000000800050fc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050fc:	7179                	addi	sp,sp,-48
    800050fe:	f406                	sd	ra,40(sp)
    80005100:	f022                	sd	s0,32(sp)
    80005102:	ec26                	sd	s1,24(sp)
    80005104:	e052                	sd	s4,0(sp)
    80005106:	1800                	addi	s0,sp,48
    80005108:	84aa                	mv	s1,a0
    8000510a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000510c:	0005b023          	sd	zero,0(a1)
    80005110:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005114:	00000097          	auipc	ra,0x0
    80005118:	bbe080e7          	jalr	-1090(ra) # 80004cd2 <filealloc>
    8000511c:	e088                	sd	a0,0(s1)
    8000511e:	cd49                	beqz	a0,800051b8 <pipealloc+0xbc>
    80005120:	00000097          	auipc	ra,0x0
    80005124:	bb2080e7          	jalr	-1102(ra) # 80004cd2 <filealloc>
    80005128:	00aa3023          	sd	a0,0(s4)
    8000512c:	c141                	beqz	a0,800051ac <pipealloc+0xb0>
    8000512e:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	a18080e7          	jalr	-1512(ra) # 80000b48 <kalloc>
    80005138:	892a                	mv	s2,a0
    8000513a:	c13d                	beqz	a0,800051a0 <pipealloc+0xa4>
    8000513c:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    8000513e:	4985                	li	s3,1
    80005140:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005144:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005148:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000514c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005150:	00003597          	auipc	a1,0x3
    80005154:	46058593          	addi	a1,a1,1120 # 800085b0 <etext+0x5b0>
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	a50080e7          	jalr	-1456(ra) # 80000ba8 <initlock>
  (*f0)->type = FD_PIPE;
    80005160:	609c                	ld	a5,0(s1)
    80005162:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005166:	609c                	ld	a5,0(s1)
    80005168:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000516c:	609c                	ld	a5,0(s1)
    8000516e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005172:	609c                	ld	a5,0(s1)
    80005174:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005178:	000a3783          	ld	a5,0(s4)
    8000517c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005180:	000a3783          	ld	a5,0(s4)
    80005184:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005188:	000a3783          	ld	a5,0(s4)
    8000518c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005190:	000a3783          	ld	a5,0(s4)
    80005194:	0127b823          	sd	s2,16(a5)
  return 0;
    80005198:	4501                	li	a0,0
    8000519a:	6942                	ld	s2,16(sp)
    8000519c:	69a2                	ld	s3,8(sp)
    8000519e:	a03d                	j	800051cc <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800051a0:	6088                	ld	a0,0(s1)
    800051a2:	c119                	beqz	a0,800051a8 <pipealloc+0xac>
    800051a4:	6942                	ld	s2,16(sp)
    800051a6:	a029                	j	800051b0 <pipealloc+0xb4>
    800051a8:	6942                	ld	s2,16(sp)
    800051aa:	a039                	j	800051b8 <pipealloc+0xbc>
    800051ac:	6088                	ld	a0,0(s1)
    800051ae:	c50d                	beqz	a0,800051d8 <pipealloc+0xdc>
    fileclose(*f0);
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	bde080e7          	jalr	-1058(ra) # 80004d8e <fileclose>
  if(*f1)
    800051b8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051bc:	557d                	li	a0,-1
  if(*f1)
    800051be:	c799                	beqz	a5,800051cc <pipealloc+0xd0>
    fileclose(*f1);
    800051c0:	853e                	mv	a0,a5
    800051c2:	00000097          	auipc	ra,0x0
    800051c6:	bcc080e7          	jalr	-1076(ra) # 80004d8e <fileclose>
  return -1;
    800051ca:	557d                	li	a0,-1
}
    800051cc:	70a2                	ld	ra,40(sp)
    800051ce:	7402                	ld	s0,32(sp)
    800051d0:	64e2                	ld	s1,24(sp)
    800051d2:	6a02                	ld	s4,0(sp)
    800051d4:	6145                	addi	sp,sp,48
    800051d6:	8082                	ret
  return -1;
    800051d8:	557d                	li	a0,-1
    800051da:	bfcd                	j	800051cc <pipealloc+0xd0>

00000000800051dc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051dc:	1101                	addi	sp,sp,-32
    800051de:	ec06                	sd	ra,24(sp)
    800051e0:	e822                	sd	s0,16(sp)
    800051e2:	e426                	sd	s1,8(sp)
    800051e4:	e04a                	sd	s2,0(sp)
    800051e6:	1000                	addi	s0,sp,32
    800051e8:	84aa                	mv	s1,a0
    800051ea:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	a4c080e7          	jalr	-1460(ra) # 80000c38 <acquire>
  if(writable){
    800051f4:	02090d63          	beqz	s2,8000522e <pipeclose+0x52>
    pi->writeopen = 0;
    800051f8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051fc:	21848513          	addi	a0,s1,536
    80005200:	ffffd097          	auipc	ra,0xffffd
    80005204:	348080e7          	jalr	840(ra) # 80002548 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005208:	2204b783          	ld	a5,544(s1)
    8000520c:	eb95                	bnez	a5,80005240 <pipeclose+0x64>
    release(&pi->lock);
    8000520e:	8526                	mv	a0,s1
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	adc080e7          	jalr	-1316(ra) # 80000cec <release>
    kfree((char*)pi);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	830080e7          	jalr	-2000(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    80005222:	60e2                	ld	ra,24(sp)
    80005224:	6442                	ld	s0,16(sp)
    80005226:	64a2                	ld	s1,8(sp)
    80005228:	6902                	ld	s2,0(sp)
    8000522a:	6105                	addi	sp,sp,32
    8000522c:	8082                	ret
    pi->readopen = 0;
    8000522e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005232:	21c48513          	addi	a0,s1,540
    80005236:	ffffd097          	auipc	ra,0xffffd
    8000523a:	312080e7          	jalr	786(ra) # 80002548 <wakeup>
    8000523e:	b7e9                	j	80005208 <pipeclose+0x2c>
    release(&pi->lock);
    80005240:	8526                	mv	a0,s1
    80005242:	ffffc097          	auipc	ra,0xffffc
    80005246:	aaa080e7          	jalr	-1366(ra) # 80000cec <release>
}
    8000524a:	bfe1                	j	80005222 <pipeclose+0x46>

000000008000524c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000524c:	711d                	addi	sp,sp,-96
    8000524e:	ec86                	sd	ra,88(sp)
    80005250:	e8a2                	sd	s0,80(sp)
    80005252:	e4a6                	sd	s1,72(sp)
    80005254:	e0ca                	sd	s2,64(sp)
    80005256:	fc4e                	sd	s3,56(sp)
    80005258:	f852                	sd	s4,48(sp)
    8000525a:	f456                	sd	s5,40(sp)
    8000525c:	1080                	addi	s0,sp,96
    8000525e:	84aa                	mv	s1,a0
    80005260:	8aae                	mv	s5,a1
    80005262:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005264:	ffffd097          	auipc	ra,0xffffd
    80005268:	816080e7          	jalr	-2026(ra) # 80001a7a <myproc>
    8000526c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000526e:	8526                	mv	a0,s1
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	9c8080e7          	jalr	-1592(ra) # 80000c38 <acquire>
  while(i < n){
    80005278:	0d405863          	blez	s4,80005348 <pipewrite+0xfc>
    8000527c:	f05a                	sd	s6,32(sp)
    8000527e:	ec5e                	sd	s7,24(sp)
    80005280:	e862                	sd	s8,16(sp)
  int i = 0;
    80005282:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005284:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005286:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000528a:	21c48b93          	addi	s7,s1,540
    8000528e:	a089                	j	800052d0 <pipewrite+0x84>
      release(&pi->lock);
    80005290:	8526                	mv	a0,s1
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	a5a080e7          	jalr	-1446(ra) # 80000cec <release>
      return -1;
    8000529a:	597d                	li	s2,-1
    8000529c:	7b02                	ld	s6,32(sp)
    8000529e:	6be2                	ld	s7,24(sp)
    800052a0:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800052a2:	854a                	mv	a0,s2
    800052a4:	60e6                	ld	ra,88(sp)
    800052a6:	6446                	ld	s0,80(sp)
    800052a8:	64a6                	ld	s1,72(sp)
    800052aa:	6906                	ld	s2,64(sp)
    800052ac:	79e2                	ld	s3,56(sp)
    800052ae:	7a42                	ld	s4,48(sp)
    800052b0:	7aa2                	ld	s5,40(sp)
    800052b2:	6125                	addi	sp,sp,96
    800052b4:	8082                	ret
      wakeup(&pi->nread);
    800052b6:	8562                	mv	a0,s8
    800052b8:	ffffd097          	auipc	ra,0xffffd
    800052bc:	290080e7          	jalr	656(ra) # 80002548 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052c0:	85a6                	mv	a1,s1
    800052c2:	855e                	mv	a0,s7
    800052c4:	ffffd097          	auipc	ra,0xffffd
    800052c8:	220080e7          	jalr	544(ra) # 800024e4 <sleep>
  while(i < n){
    800052cc:	05495f63          	bge	s2,s4,8000532a <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    800052d0:	2204a783          	lw	a5,544(s1)
    800052d4:	dfd5                	beqz	a5,80005290 <pipewrite+0x44>
    800052d6:	854e                	mv	a0,s3
    800052d8:	ffffd097          	auipc	ra,0xffffd
    800052dc:	4c0080e7          	jalr	1216(ra) # 80002798 <killed>
    800052e0:	f945                	bnez	a0,80005290 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052e2:	2184a783          	lw	a5,536(s1)
    800052e6:	21c4a703          	lw	a4,540(s1)
    800052ea:	2007879b          	addiw	a5,a5,512
    800052ee:	fcf704e3          	beq	a4,a5,800052b6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052f2:	4685                	li	a3,1
    800052f4:	01590633          	add	a2,s2,s5
    800052f8:	faf40593          	addi	a1,s0,-81
    800052fc:	2289b503          	ld	a0,552(s3)
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	46e080e7          	jalr	1134(ra) # 8000176e <copyin>
    80005308:	05650263          	beq	a0,s6,8000534c <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000530c:	21c4a783          	lw	a5,540(s1)
    80005310:	0017871b          	addiw	a4,a5,1
    80005314:	20e4ae23          	sw	a4,540(s1)
    80005318:	1ff7f793          	andi	a5,a5,511
    8000531c:	97a6                	add	a5,a5,s1
    8000531e:	faf44703          	lbu	a4,-81(s0)
    80005322:	00e78c23          	sb	a4,24(a5)
      i++;
    80005326:	2905                	addiw	s2,s2,1
    80005328:	b755                	j	800052cc <pipewrite+0x80>
    8000532a:	7b02                	ld	s6,32(sp)
    8000532c:	6be2                	ld	s7,24(sp)
    8000532e:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80005330:	21848513          	addi	a0,s1,536
    80005334:	ffffd097          	auipc	ra,0xffffd
    80005338:	214080e7          	jalr	532(ra) # 80002548 <wakeup>
  release(&pi->lock);
    8000533c:	8526                	mv	a0,s1
    8000533e:	ffffc097          	auipc	ra,0xffffc
    80005342:	9ae080e7          	jalr	-1618(ra) # 80000cec <release>
  return i;
    80005346:	bfb1                	j	800052a2 <pipewrite+0x56>
  int i = 0;
    80005348:	4901                	li	s2,0
    8000534a:	b7dd                	j	80005330 <pipewrite+0xe4>
    8000534c:	7b02                	ld	s6,32(sp)
    8000534e:	6be2                	ld	s7,24(sp)
    80005350:	6c42                	ld	s8,16(sp)
    80005352:	bff9                	j	80005330 <pipewrite+0xe4>

0000000080005354 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005354:	715d                	addi	sp,sp,-80
    80005356:	e486                	sd	ra,72(sp)
    80005358:	e0a2                	sd	s0,64(sp)
    8000535a:	fc26                	sd	s1,56(sp)
    8000535c:	f84a                	sd	s2,48(sp)
    8000535e:	f44e                	sd	s3,40(sp)
    80005360:	f052                	sd	s4,32(sp)
    80005362:	ec56                	sd	s5,24(sp)
    80005364:	0880                	addi	s0,sp,80
    80005366:	84aa                	mv	s1,a0
    80005368:	892e                	mv	s2,a1
    8000536a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	70e080e7          	jalr	1806(ra) # 80001a7a <myproc>
    80005374:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005376:	8526                	mv	a0,s1
    80005378:	ffffc097          	auipc	ra,0xffffc
    8000537c:	8c0080e7          	jalr	-1856(ra) # 80000c38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005380:	2184a703          	lw	a4,536(s1)
    80005384:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005388:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000538c:	02f71963          	bne	a4,a5,800053be <piperead+0x6a>
    80005390:	2244a783          	lw	a5,548(s1)
    80005394:	cf95                	beqz	a5,800053d0 <piperead+0x7c>
    if(killed(pr)){
    80005396:	8552                	mv	a0,s4
    80005398:	ffffd097          	auipc	ra,0xffffd
    8000539c:	400080e7          	jalr	1024(ra) # 80002798 <killed>
    800053a0:	e10d                	bnez	a0,800053c2 <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053a2:	85a6                	mv	a1,s1
    800053a4:	854e                	mv	a0,s3
    800053a6:	ffffd097          	auipc	ra,0xffffd
    800053aa:	13e080e7          	jalr	318(ra) # 800024e4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053ae:	2184a703          	lw	a4,536(s1)
    800053b2:	21c4a783          	lw	a5,540(s1)
    800053b6:	fcf70de3          	beq	a4,a5,80005390 <piperead+0x3c>
    800053ba:	e85a                	sd	s6,16(sp)
    800053bc:	a819                	j	800053d2 <piperead+0x7e>
    800053be:	e85a                	sd	s6,16(sp)
    800053c0:	a809                	j	800053d2 <piperead+0x7e>
      release(&pi->lock);
    800053c2:	8526                	mv	a0,s1
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	928080e7          	jalr	-1752(ra) # 80000cec <release>
      return -1;
    800053cc:	59fd                	li	s3,-1
    800053ce:	a0a5                	j	80005436 <piperead+0xe2>
    800053d0:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053d2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053d4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053d6:	05505463          	blez	s5,8000541e <piperead+0xca>
    if(pi->nread == pi->nwrite)
    800053da:	2184a783          	lw	a5,536(s1)
    800053de:	21c4a703          	lw	a4,540(s1)
    800053e2:	02f70e63          	beq	a4,a5,8000541e <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053e6:	0017871b          	addiw	a4,a5,1
    800053ea:	20e4ac23          	sw	a4,536(s1)
    800053ee:	1ff7f793          	andi	a5,a5,511
    800053f2:	97a6                	add	a5,a5,s1
    800053f4:	0187c783          	lbu	a5,24(a5)
    800053f8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053fc:	4685                	li	a3,1
    800053fe:	fbf40613          	addi	a2,s0,-65
    80005402:	85ca                	mv	a1,s2
    80005404:	228a3503          	ld	a0,552(s4)
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	2da080e7          	jalr	730(ra) # 800016e2 <copyout>
    80005410:	01650763          	beq	a0,s6,8000541e <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005414:	2985                	addiw	s3,s3,1
    80005416:	0905                	addi	s2,s2,1
    80005418:	fd3a91e3          	bne	s5,s3,800053da <piperead+0x86>
    8000541c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000541e:	21c48513          	addi	a0,s1,540
    80005422:	ffffd097          	auipc	ra,0xffffd
    80005426:	126080e7          	jalr	294(ra) # 80002548 <wakeup>
  release(&pi->lock);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	8c0080e7          	jalr	-1856(ra) # 80000cec <release>
    80005434:	6b42                	ld	s6,16(sp)
  return i;
}
    80005436:	854e                	mv	a0,s3
    80005438:	60a6                	ld	ra,72(sp)
    8000543a:	6406                	ld	s0,64(sp)
    8000543c:	74e2                	ld	s1,56(sp)
    8000543e:	7942                	ld	s2,48(sp)
    80005440:	79a2                	ld	s3,40(sp)
    80005442:	7a02                	ld	s4,32(sp)
    80005444:	6ae2                	ld	s5,24(sp)
    80005446:	6161                	addi	sp,sp,80
    80005448:	8082                	ret

000000008000544a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000544a:	1141                	addi	sp,sp,-16
    8000544c:	e422                	sd	s0,8(sp)
    8000544e:	0800                	addi	s0,sp,16
    80005450:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005452:	8905                	andi	a0,a0,1
    80005454:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005456:	8b89                	andi	a5,a5,2
    80005458:	c399                	beqz	a5,8000545e <flags2perm+0x14>
      perm |= PTE_W;
    8000545a:	00456513          	ori	a0,a0,4
    return perm;
}
    8000545e:	6422                	ld	s0,8(sp)
    80005460:	0141                	addi	sp,sp,16
    80005462:	8082                	ret

0000000080005464 <exec>:

int
exec(char *path, char **argv)
{
    80005464:	df010113          	addi	sp,sp,-528
    80005468:	20113423          	sd	ra,520(sp)
    8000546c:	20813023          	sd	s0,512(sp)
    80005470:	ffa6                	sd	s1,504(sp)
    80005472:	fbca                	sd	s2,496(sp)
    80005474:	0c00                	addi	s0,sp,528
    80005476:	892a                	mv	s2,a0
    80005478:	dea43c23          	sd	a0,-520(s0)
    8000547c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005480:	ffffc097          	auipc	ra,0xffffc
    80005484:	5fa080e7          	jalr	1530(ra) # 80001a7a <myproc>
    80005488:	84aa                	mv	s1,a0

  begin_op();
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	43a080e7          	jalr	1082(ra) # 800048c4 <begin_op>

  if((ip = namei(path)) == 0){
    80005492:	854a                	mv	a0,s2
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	230080e7          	jalr	560(ra) # 800046c4 <namei>
    8000549c:	c135                	beqz	a0,80005500 <exec+0x9c>
    8000549e:	f3d2                	sd	s4,480(sp)
    800054a0:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	a54080e7          	jalr	-1452(ra) # 80003ef6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800054aa:	04000713          	li	a4,64
    800054ae:	4681                	li	a3,0
    800054b0:	e5040613          	addi	a2,s0,-432
    800054b4:	4581                	li	a1,0
    800054b6:	8552                	mv	a0,s4
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	cf6080e7          	jalr	-778(ra) # 800041ae <readi>
    800054c0:	04000793          	li	a5,64
    800054c4:	00f51a63          	bne	a0,a5,800054d8 <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800054c8:	e5042703          	lw	a4,-432(s0)
    800054cc:	464c47b7          	lui	a5,0x464c4
    800054d0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054d4:	02f70c63          	beq	a4,a5,8000550c <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054d8:	8552                	mv	a0,s4
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	c82080e7          	jalr	-894(ra) # 8000415c <iunlockput>
    end_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	45c080e7          	jalr	1116(ra) # 8000493e <end_op>
  }
  return -1;
    800054ea:	557d                	li	a0,-1
    800054ec:	7a1e                	ld	s4,480(sp)
}
    800054ee:	20813083          	ld	ra,520(sp)
    800054f2:	20013403          	ld	s0,512(sp)
    800054f6:	74fe                	ld	s1,504(sp)
    800054f8:	795e                	ld	s2,496(sp)
    800054fa:	21010113          	addi	sp,sp,528
    800054fe:	8082                	ret
    end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	43e080e7          	jalr	1086(ra) # 8000493e <end_op>
    return -1;
    80005508:	557d                	li	a0,-1
    8000550a:	b7d5                	j	800054ee <exec+0x8a>
    8000550c:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffc097          	auipc	ra,0xffffc
    80005514:	62e080e7          	jalr	1582(ra) # 80001b3e <proc_pagetable>
    80005518:	8b2a                	mv	s6,a0
    8000551a:	30050f63          	beqz	a0,80005838 <exec+0x3d4>
    8000551e:	f7ce                	sd	s3,488(sp)
    80005520:	efd6                	sd	s5,472(sp)
    80005522:	e7de                	sd	s7,456(sp)
    80005524:	e3e2                	sd	s8,448(sp)
    80005526:	ff66                	sd	s9,440(sp)
    80005528:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000552a:	e7042d03          	lw	s10,-400(s0)
    8000552e:	e8845783          	lhu	a5,-376(s0)
    80005532:	14078d63          	beqz	a5,8000568c <exec+0x228>
    80005536:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005538:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000553a:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    8000553c:	6c85                	lui	s9,0x1
    8000553e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005542:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005546:	6a85                	lui	s5,0x1
    80005548:	a0b5                	j	800055b4 <exec+0x150>
      panic("loadseg: address should exist");
    8000554a:	00003517          	auipc	a0,0x3
    8000554e:	06e50513          	addi	a0,a0,110 # 800085b8 <etext+0x5b8>
    80005552:	ffffb097          	auipc	ra,0xffffb
    80005556:	00e080e7          	jalr	14(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    8000555a:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000555c:	8726                	mv	a4,s1
    8000555e:	012c06bb          	addw	a3,s8,s2
    80005562:	4581                	li	a1,0
    80005564:	8552                	mv	a0,s4
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	c48080e7          	jalr	-952(ra) # 800041ae <readi>
    8000556e:	2501                	sext.w	a0,a0
    80005570:	28a49863          	bne	s1,a0,80005800 <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    80005574:	012a893b          	addw	s2,s5,s2
    80005578:	03397563          	bgeu	s2,s3,800055a2 <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    8000557c:	02091593          	slli	a1,s2,0x20
    80005580:	9181                	srli	a1,a1,0x20
    80005582:	95de                	add	a1,a1,s7
    80005584:	855a                	mv	a0,s6
    80005586:	ffffc097          	auipc	ra,0xffffc
    8000558a:	b30080e7          	jalr	-1232(ra) # 800010b6 <walkaddr>
    8000558e:	862a                	mv	a2,a0
    if(pa == 0)
    80005590:	dd4d                	beqz	a0,8000554a <exec+0xe6>
    if(sz - i < PGSIZE)
    80005592:	412984bb          	subw	s1,s3,s2
    80005596:	0004879b          	sext.w	a5,s1
    8000559a:	fcfcf0e3          	bgeu	s9,a5,8000555a <exec+0xf6>
    8000559e:	84d6                	mv	s1,s5
    800055a0:	bf6d                	j	8000555a <exec+0xf6>
    sz = sz1;
    800055a2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055a6:	2d85                	addiw	s11,s11,1
    800055a8:	038d0d1b          	addiw	s10,s10,56
    800055ac:	e8845783          	lhu	a5,-376(s0)
    800055b0:	08fdd663          	bge	s11,a5,8000563c <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055b4:	2d01                	sext.w	s10,s10
    800055b6:	03800713          	li	a4,56
    800055ba:	86ea                	mv	a3,s10
    800055bc:	e1840613          	addi	a2,s0,-488
    800055c0:	4581                	li	a1,0
    800055c2:	8552                	mv	a0,s4
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	bea080e7          	jalr	-1046(ra) # 800041ae <readi>
    800055cc:	03800793          	li	a5,56
    800055d0:	20f51063          	bne	a0,a5,800057d0 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    800055d4:	e1842783          	lw	a5,-488(s0)
    800055d8:	4705                	li	a4,1
    800055da:	fce796e3          	bne	a5,a4,800055a6 <exec+0x142>
    if(ph.memsz < ph.filesz)
    800055de:	e4043483          	ld	s1,-448(s0)
    800055e2:	e3843783          	ld	a5,-456(s0)
    800055e6:	1ef4e963          	bltu	s1,a5,800057d8 <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800055ea:	e2843783          	ld	a5,-472(s0)
    800055ee:	94be                	add	s1,s1,a5
    800055f0:	1ef4e863          	bltu	s1,a5,800057e0 <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    800055f4:	df043703          	ld	a4,-528(s0)
    800055f8:	8ff9                	and	a5,a5,a4
    800055fa:	1e079763          	bnez	a5,800057e8 <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055fe:	e1c42503          	lw	a0,-484(s0)
    80005602:	00000097          	auipc	ra,0x0
    80005606:	e48080e7          	jalr	-440(ra) # 8000544a <flags2perm>
    8000560a:	86aa                	mv	a3,a0
    8000560c:	8626                	mv	a2,s1
    8000560e:	85ca                	mv	a1,s2
    80005610:	855a                	mv	a0,s6
    80005612:	ffffc097          	auipc	ra,0xffffc
    80005616:	e68080e7          	jalr	-408(ra) # 8000147a <uvmalloc>
    8000561a:	e0a43423          	sd	a0,-504(s0)
    8000561e:	1c050963          	beqz	a0,800057f0 <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005622:	e2843b83          	ld	s7,-472(s0)
    80005626:	e2042c03          	lw	s8,-480(s0)
    8000562a:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000562e:	00098463          	beqz	s3,80005636 <exec+0x1d2>
    80005632:	4901                	li	s2,0
    80005634:	b7a1                	j	8000557c <exec+0x118>
    sz = sz1;
    80005636:	e0843903          	ld	s2,-504(s0)
    8000563a:	b7b5                	j	800055a6 <exec+0x142>
    8000563c:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    8000563e:	8552                	mv	a0,s4
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	b1c080e7          	jalr	-1252(ra) # 8000415c <iunlockput>
  end_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	2f6080e7          	jalr	758(ra) # 8000493e <end_op>
  p = myproc();
    80005650:	ffffc097          	auipc	ra,0xffffc
    80005654:	42a080e7          	jalr	1066(ra) # 80001a7a <myproc>
    80005658:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000565a:	22053c83          	ld	s9,544(a0)
  sz = PGROUNDUP(sz);
    8000565e:	6985                	lui	s3,0x1
    80005660:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005662:	99ca                	add	s3,s3,s2
    80005664:	77fd                	lui	a5,0xfffff
    80005666:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000566a:	4691                	li	a3,4
    8000566c:	6609                	lui	a2,0x2
    8000566e:	964e                	add	a2,a2,s3
    80005670:	85ce                	mv	a1,s3
    80005672:	855a                	mv	a0,s6
    80005674:	ffffc097          	auipc	ra,0xffffc
    80005678:	e06080e7          	jalr	-506(ra) # 8000147a <uvmalloc>
    8000567c:	892a                	mv	s2,a0
    8000567e:	e0a43423          	sd	a0,-504(s0)
    80005682:	e519                	bnez	a0,80005690 <exec+0x22c>
  if(pagetable)
    80005684:	e1343423          	sd	s3,-504(s0)
    80005688:	4a01                	li	s4,0
    8000568a:	aaa5                	j	80005802 <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000568c:	4901                	li	s2,0
    8000568e:	bf45                	j	8000563e <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005690:	75f9                	lui	a1,0xffffe
    80005692:	95aa                	add	a1,a1,a0
    80005694:	855a                	mv	a0,s6
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	01a080e7          	jalr	26(ra) # 800016b0 <uvmclear>
  stackbase = sp - PGSIZE;
    8000569e:	7bfd                	lui	s7,0xfffff
    800056a0:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800056a2:	e0043783          	ld	a5,-512(s0)
    800056a6:	6388                	ld	a0,0(a5)
    800056a8:	c52d                	beqz	a0,80005712 <exec+0x2ae>
    800056aa:	e9040993          	addi	s3,s0,-368
    800056ae:	f9040c13          	addi	s8,s0,-112
    800056b2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800056b4:	ffffb097          	auipc	ra,0xffffb
    800056b8:	7f4080e7          	jalr	2036(ra) # 80000ea8 <strlen>
    800056bc:	0015079b          	addiw	a5,a0,1
    800056c0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800056c4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800056c8:	13796863          	bltu	s2,s7,800057f8 <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056cc:	e0043d03          	ld	s10,-512(s0)
    800056d0:	000d3a03          	ld	s4,0(s10)
    800056d4:	8552                	mv	a0,s4
    800056d6:	ffffb097          	auipc	ra,0xffffb
    800056da:	7d2080e7          	jalr	2002(ra) # 80000ea8 <strlen>
    800056de:	0015069b          	addiw	a3,a0,1
    800056e2:	8652                	mv	a2,s4
    800056e4:	85ca                	mv	a1,s2
    800056e6:	855a                	mv	a0,s6
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	ffa080e7          	jalr	-6(ra) # 800016e2 <copyout>
    800056f0:	10054663          	bltz	a0,800057fc <exec+0x398>
    ustack[argc] = sp;
    800056f4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056f8:	0485                	addi	s1,s1,1
    800056fa:	008d0793          	addi	a5,s10,8
    800056fe:	e0f43023          	sd	a5,-512(s0)
    80005702:	008d3503          	ld	a0,8(s10)
    80005706:	c909                	beqz	a0,80005718 <exec+0x2b4>
    if(argc >= MAXARG)
    80005708:	09a1                	addi	s3,s3,8
    8000570a:	fb8995e3          	bne	s3,s8,800056b4 <exec+0x250>
  ip = 0;
    8000570e:	4a01                	li	s4,0
    80005710:	a8cd                	j	80005802 <exec+0x39e>
  sp = sz;
    80005712:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005716:	4481                	li	s1,0
  ustack[argc] = 0;
    80005718:	00349793          	slli	a5,s1,0x3
    8000571c:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd24f0>
    80005720:	97a2                	add	a5,a5,s0
    80005722:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005726:	00148693          	addi	a3,s1,1
    8000572a:	068e                	slli	a3,a3,0x3
    8000572c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005730:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005734:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005738:	f57966e3          	bltu	s2,s7,80005684 <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000573c:	e9040613          	addi	a2,s0,-368
    80005740:	85ca                	mv	a1,s2
    80005742:	855a                	mv	a0,s6
    80005744:	ffffc097          	auipc	ra,0xffffc
    80005748:	f9e080e7          	jalr	-98(ra) # 800016e2 <copyout>
    8000574c:	0e054863          	bltz	a0,8000583c <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005750:	230ab783          	ld	a5,560(s5) # 1230 <_entry-0x7fffedd0>
    80005754:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005758:	df843783          	ld	a5,-520(s0)
    8000575c:	0007c703          	lbu	a4,0(a5)
    80005760:	cf11                	beqz	a4,8000577c <exec+0x318>
    80005762:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005764:	02f00693          	li	a3,47
    80005768:	a039                	j	80005776 <exec+0x312>
      last = s+1;
    8000576a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000576e:	0785                	addi	a5,a5,1
    80005770:	fff7c703          	lbu	a4,-1(a5)
    80005774:	c701                	beqz	a4,8000577c <exec+0x318>
    if(*s == '/')
    80005776:	fed71ce3          	bne	a4,a3,8000576e <exec+0x30a>
    8000577a:	bfc5                	j	8000576a <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    8000577c:	4641                	li	a2,16
    8000577e:	df843583          	ld	a1,-520(s0)
    80005782:	330a8513          	addi	a0,s5,816
    80005786:	ffffb097          	auipc	ra,0xffffb
    8000578a:	6f0080e7          	jalr	1776(ra) # 80000e76 <safestrcpy>
  oldpagetable = p->pagetable;
    8000578e:	228ab503          	ld	a0,552(s5)
  p->pagetable = pagetable;
    80005792:	236ab423          	sd	s6,552(s5)
  p->sz = sz;
    80005796:	e0843783          	ld	a5,-504(s0)
    8000579a:	22fab023          	sd	a5,544(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000579e:	230ab783          	ld	a5,560(s5)
    800057a2:	e6843703          	ld	a4,-408(s0)
    800057a6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800057a8:	230ab783          	ld	a5,560(s5)
    800057ac:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800057b0:	85e6                	mv	a1,s9
    800057b2:	ffffc097          	auipc	ra,0xffffc
    800057b6:	428080e7          	jalr	1064(ra) # 80001bda <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800057ba:	0004851b          	sext.w	a0,s1
    800057be:	79be                	ld	s3,488(sp)
    800057c0:	7a1e                	ld	s4,480(sp)
    800057c2:	6afe                	ld	s5,472(sp)
    800057c4:	6b5e                	ld	s6,464(sp)
    800057c6:	6bbe                	ld	s7,456(sp)
    800057c8:	6c1e                	ld	s8,448(sp)
    800057ca:	7cfa                	ld	s9,440(sp)
    800057cc:	7d5a                	ld	s10,432(sp)
    800057ce:	b305                	j	800054ee <exec+0x8a>
    800057d0:	e1243423          	sd	s2,-504(s0)
    800057d4:	7dba                	ld	s11,424(sp)
    800057d6:	a035                	j	80005802 <exec+0x39e>
    800057d8:	e1243423          	sd	s2,-504(s0)
    800057dc:	7dba                	ld	s11,424(sp)
    800057de:	a015                	j	80005802 <exec+0x39e>
    800057e0:	e1243423          	sd	s2,-504(s0)
    800057e4:	7dba                	ld	s11,424(sp)
    800057e6:	a831                	j	80005802 <exec+0x39e>
    800057e8:	e1243423          	sd	s2,-504(s0)
    800057ec:	7dba                	ld	s11,424(sp)
    800057ee:	a811                	j	80005802 <exec+0x39e>
    800057f0:	e1243423          	sd	s2,-504(s0)
    800057f4:	7dba                	ld	s11,424(sp)
    800057f6:	a031                	j	80005802 <exec+0x39e>
  ip = 0;
    800057f8:	4a01                	li	s4,0
    800057fa:	a021                	j	80005802 <exec+0x39e>
    800057fc:	4a01                	li	s4,0
  if(pagetable)
    800057fe:	a011                	j	80005802 <exec+0x39e>
    80005800:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80005802:	e0843583          	ld	a1,-504(s0)
    80005806:	855a                	mv	a0,s6
    80005808:	ffffc097          	auipc	ra,0xffffc
    8000580c:	3d2080e7          	jalr	978(ra) # 80001bda <proc_freepagetable>
  return -1;
    80005810:	557d                	li	a0,-1
  if(ip){
    80005812:	000a1b63          	bnez	s4,80005828 <exec+0x3c4>
    80005816:	79be                	ld	s3,488(sp)
    80005818:	7a1e                	ld	s4,480(sp)
    8000581a:	6afe                	ld	s5,472(sp)
    8000581c:	6b5e                	ld	s6,464(sp)
    8000581e:	6bbe                	ld	s7,456(sp)
    80005820:	6c1e                	ld	s8,448(sp)
    80005822:	7cfa                	ld	s9,440(sp)
    80005824:	7d5a                	ld	s10,432(sp)
    80005826:	b1e1                	j	800054ee <exec+0x8a>
    80005828:	79be                	ld	s3,488(sp)
    8000582a:	6afe                	ld	s5,472(sp)
    8000582c:	6b5e                	ld	s6,464(sp)
    8000582e:	6bbe                	ld	s7,456(sp)
    80005830:	6c1e                	ld	s8,448(sp)
    80005832:	7cfa                	ld	s9,440(sp)
    80005834:	7d5a                	ld	s10,432(sp)
    80005836:	b14d                	j	800054d8 <exec+0x74>
    80005838:	6b5e                	ld	s6,464(sp)
    8000583a:	b979                	j	800054d8 <exec+0x74>
  sz = sz1;
    8000583c:	e0843983          	ld	s3,-504(s0)
    80005840:	b591                	j	80005684 <exec+0x220>

0000000080005842 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005842:	7179                	addi	sp,sp,-48
    80005844:	f406                	sd	ra,40(sp)
    80005846:	f022                	sd	s0,32(sp)
    80005848:	ec26                	sd	s1,24(sp)
    8000584a:	e84a                	sd	s2,16(sp)
    8000584c:	1800                	addi	s0,sp,48
    8000584e:	892e                	mv	s2,a1
    80005850:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005852:	fdc40593          	addi	a1,s0,-36
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	95c080e7          	jalr	-1700(ra) # 800031b2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000585e:	fdc42703          	lw	a4,-36(s0)
    80005862:	47bd                	li	a5,15
    80005864:	02e7eb63          	bltu	a5,a4,8000589a <argfd+0x58>
    80005868:	ffffc097          	auipc	ra,0xffffc
    8000586c:	212080e7          	jalr	530(ra) # 80001a7a <myproc>
    80005870:	fdc42703          	lw	a4,-36(s0)
    80005874:	05470793          	addi	a5,a4,84
    80005878:	078e                	slli	a5,a5,0x3
    8000587a:	953e                	add	a0,a0,a5
    8000587c:	651c                	ld	a5,8(a0)
    8000587e:	c385                	beqz	a5,8000589e <argfd+0x5c>
    return -1;
  if(pfd)
    80005880:	00090463          	beqz	s2,80005888 <argfd+0x46>
    *pfd = fd;
    80005884:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005888:	4501                	li	a0,0
  if(pf)
    8000588a:	c091                	beqz	s1,8000588e <argfd+0x4c>
    *pf = f;
    8000588c:	e09c                	sd	a5,0(s1)
}
    8000588e:	70a2                	ld	ra,40(sp)
    80005890:	7402                	ld	s0,32(sp)
    80005892:	64e2                	ld	s1,24(sp)
    80005894:	6942                	ld	s2,16(sp)
    80005896:	6145                	addi	sp,sp,48
    80005898:	8082                	ret
    return -1;
    8000589a:	557d                	li	a0,-1
    8000589c:	bfcd                	j	8000588e <argfd+0x4c>
    8000589e:	557d                	li	a0,-1
    800058a0:	b7fd                	j	8000588e <argfd+0x4c>

00000000800058a2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058a2:	1101                	addi	sp,sp,-32
    800058a4:	ec06                	sd	ra,24(sp)
    800058a6:	e822                	sd	s0,16(sp)
    800058a8:	e426                	sd	s1,8(sp)
    800058aa:	1000                	addi	s0,sp,32
    800058ac:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058ae:	ffffc097          	auipc	ra,0xffffc
    800058b2:	1cc080e7          	jalr	460(ra) # 80001a7a <myproc>
    800058b6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058b8:	2a850793          	addi	a5,a0,680
    800058bc:	4501                	li	a0,0
    800058be:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058c0:	6398                	ld	a4,0(a5)
    800058c2:	cb19                	beqz	a4,800058d8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058c4:	2505                	addiw	a0,a0,1
    800058c6:	07a1                	addi	a5,a5,8
    800058c8:	fed51ce3          	bne	a0,a3,800058c0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058cc:	557d                	li	a0,-1
}
    800058ce:	60e2                	ld	ra,24(sp)
    800058d0:	6442                	ld	s0,16(sp)
    800058d2:	64a2                	ld	s1,8(sp)
    800058d4:	6105                	addi	sp,sp,32
    800058d6:	8082                	ret
      p->ofile[fd] = f;
    800058d8:	05450793          	addi	a5,a0,84
    800058dc:	078e                	slli	a5,a5,0x3
    800058de:	963e                	add	a2,a2,a5
    800058e0:	e604                	sd	s1,8(a2)
      return fd;
    800058e2:	b7f5                	j	800058ce <fdalloc+0x2c>

00000000800058e4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058e4:	715d                	addi	sp,sp,-80
    800058e6:	e486                	sd	ra,72(sp)
    800058e8:	e0a2                	sd	s0,64(sp)
    800058ea:	fc26                	sd	s1,56(sp)
    800058ec:	f84a                	sd	s2,48(sp)
    800058ee:	f44e                	sd	s3,40(sp)
    800058f0:	ec56                	sd	s5,24(sp)
    800058f2:	e85a                	sd	s6,16(sp)
    800058f4:	0880                	addi	s0,sp,80
    800058f6:	8b2e                	mv	s6,a1
    800058f8:	89b2                	mv	s3,a2
    800058fa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800058fc:	fb040593          	addi	a1,s0,-80
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	de2080e7          	jalr	-542(ra) # 800046e2 <nameiparent>
    80005908:	84aa                	mv	s1,a0
    8000590a:	14050e63          	beqz	a0,80005a66 <create+0x182>
    return 0;

  ilock(dp);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	5e8080e7          	jalr	1512(ra) # 80003ef6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005916:	4601                	li	a2,0
    80005918:	fb040593          	addi	a1,s0,-80
    8000591c:	8526                	mv	a0,s1
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	ae4080e7          	jalr	-1308(ra) # 80004402 <dirlookup>
    80005926:	8aaa                	mv	s5,a0
    80005928:	c539                	beqz	a0,80005976 <create+0x92>
    iunlockput(dp);
    8000592a:	8526                	mv	a0,s1
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	830080e7          	jalr	-2000(ra) # 8000415c <iunlockput>
    ilock(ip);
    80005934:	8556                	mv	a0,s5
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	5c0080e7          	jalr	1472(ra) # 80003ef6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000593e:	4789                	li	a5,2
    80005940:	02fb1463          	bne	s6,a5,80005968 <create+0x84>
    80005944:	044ad783          	lhu	a5,68(s5)
    80005948:	37f9                	addiw	a5,a5,-2
    8000594a:	17c2                	slli	a5,a5,0x30
    8000594c:	93c1                	srli	a5,a5,0x30
    8000594e:	4705                	li	a4,1
    80005950:	00f76c63          	bltu	a4,a5,80005968 <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005954:	8556                	mv	a0,s5
    80005956:	60a6                	ld	ra,72(sp)
    80005958:	6406                	ld	s0,64(sp)
    8000595a:	74e2                	ld	s1,56(sp)
    8000595c:	7942                	ld	s2,48(sp)
    8000595e:	79a2                	ld	s3,40(sp)
    80005960:	6ae2                	ld	s5,24(sp)
    80005962:	6b42                	ld	s6,16(sp)
    80005964:	6161                	addi	sp,sp,80
    80005966:	8082                	ret
    iunlockput(ip);
    80005968:	8556                	mv	a0,s5
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	7f2080e7          	jalr	2034(ra) # 8000415c <iunlockput>
    return 0;
    80005972:	4a81                	li	s5,0
    80005974:	b7c5                	j	80005954 <create+0x70>
    80005976:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005978:	85da                	mv	a1,s6
    8000597a:	4088                	lw	a0,0(s1)
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	3d6080e7          	jalr	982(ra) # 80003d52 <ialloc>
    80005984:	8a2a                	mv	s4,a0
    80005986:	c531                	beqz	a0,800059d2 <create+0xee>
  ilock(ip);
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	56e080e7          	jalr	1390(ra) # 80003ef6 <ilock>
  ip->major = major;
    80005990:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005994:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005998:	4905                	li	s2,1
    8000599a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000599e:	8552                	mv	a0,s4
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	48a080e7          	jalr	1162(ra) # 80003e2a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059a8:	032b0d63          	beq	s6,s2,800059e2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800059ac:	004a2603          	lw	a2,4(s4)
    800059b0:	fb040593          	addi	a1,s0,-80
    800059b4:	8526                	mv	a0,s1
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	c5c080e7          	jalr	-932(ra) # 80004612 <dirlink>
    800059be:	08054163          	bltz	a0,80005a40 <create+0x15c>
  iunlockput(dp);
    800059c2:	8526                	mv	a0,s1
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	798080e7          	jalr	1944(ra) # 8000415c <iunlockput>
  return ip;
    800059cc:	8ad2                	mv	s5,s4
    800059ce:	7a02                	ld	s4,32(sp)
    800059d0:	b751                	j	80005954 <create+0x70>
    iunlockput(dp);
    800059d2:	8526                	mv	a0,s1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	788080e7          	jalr	1928(ra) # 8000415c <iunlockput>
    return 0;
    800059dc:	8ad2                	mv	s5,s4
    800059de:	7a02                	ld	s4,32(sp)
    800059e0:	bf95                	j	80005954 <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800059e2:	004a2603          	lw	a2,4(s4)
    800059e6:	00003597          	auipc	a1,0x3
    800059ea:	bf258593          	addi	a1,a1,-1038 # 800085d8 <etext+0x5d8>
    800059ee:	8552                	mv	a0,s4
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	c22080e7          	jalr	-990(ra) # 80004612 <dirlink>
    800059f8:	04054463          	bltz	a0,80005a40 <create+0x15c>
    800059fc:	40d0                	lw	a2,4(s1)
    800059fe:	00003597          	auipc	a1,0x3
    80005a02:	be258593          	addi	a1,a1,-1054 # 800085e0 <etext+0x5e0>
    80005a06:	8552                	mv	a0,s4
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	c0a080e7          	jalr	-1014(ra) # 80004612 <dirlink>
    80005a10:	02054863          	bltz	a0,80005a40 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a14:	004a2603          	lw	a2,4(s4)
    80005a18:	fb040593          	addi	a1,s0,-80
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	bf4080e7          	jalr	-1036(ra) # 80004612 <dirlink>
    80005a26:	00054d63          	bltz	a0,80005a40 <create+0x15c>
    dp->nlink++;  // for ".."
    80005a2a:	04a4d783          	lhu	a5,74(s1)
    80005a2e:	2785                	addiw	a5,a5,1
    80005a30:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	3f4080e7          	jalr	1012(ra) # 80003e2a <iupdate>
    80005a3e:	b751                	j	800059c2 <create+0xde>
  ip->nlink = 0;
    80005a40:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005a44:	8552                	mv	a0,s4
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	3e4080e7          	jalr	996(ra) # 80003e2a <iupdate>
  iunlockput(ip);
    80005a4e:	8552                	mv	a0,s4
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	70c080e7          	jalr	1804(ra) # 8000415c <iunlockput>
  iunlockput(dp);
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	702080e7          	jalr	1794(ra) # 8000415c <iunlockput>
  return 0;
    80005a62:	7a02                	ld	s4,32(sp)
    80005a64:	bdc5                	j	80005954 <create+0x70>
    return 0;
    80005a66:	8aaa                	mv	s5,a0
    80005a68:	b5f5                	j	80005954 <create+0x70>

0000000080005a6a <sys_dup>:
{
    80005a6a:	7179                	addi	sp,sp,-48
    80005a6c:	f406                	sd	ra,40(sp)
    80005a6e:	f022                	sd	s0,32(sp)
    80005a70:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a72:	fd840613          	addi	a2,s0,-40
    80005a76:	4581                	li	a1,0
    80005a78:	4501                	li	a0,0
    80005a7a:	00000097          	auipc	ra,0x0
    80005a7e:	dc8080e7          	jalr	-568(ra) # 80005842 <argfd>
    return -1;
    80005a82:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a84:	02054763          	bltz	a0,80005ab2 <sys_dup+0x48>
    80005a88:	ec26                	sd	s1,24(sp)
    80005a8a:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005a8c:	fd843903          	ld	s2,-40(s0)
    80005a90:	854a                	mv	a0,s2
    80005a92:	00000097          	auipc	ra,0x0
    80005a96:	e10080e7          	jalr	-496(ra) # 800058a2 <fdalloc>
    80005a9a:	84aa                	mv	s1,a0
    return -1;
    80005a9c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a9e:	00054f63          	bltz	a0,80005abc <sys_dup+0x52>
  filedup(f);
    80005aa2:	854a                	mv	a0,s2
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	298080e7          	jalr	664(ra) # 80004d3c <filedup>
  return fd;
    80005aac:	87a6                	mv	a5,s1
    80005aae:	64e2                	ld	s1,24(sp)
    80005ab0:	6942                	ld	s2,16(sp)
}
    80005ab2:	853e                	mv	a0,a5
    80005ab4:	70a2                	ld	ra,40(sp)
    80005ab6:	7402                	ld	s0,32(sp)
    80005ab8:	6145                	addi	sp,sp,48
    80005aba:	8082                	ret
    80005abc:	64e2                	ld	s1,24(sp)
    80005abe:	6942                	ld	s2,16(sp)
    80005ac0:	bfcd                	j	80005ab2 <sys_dup+0x48>

0000000080005ac2 <sys_read>:
{
    80005ac2:	7179                	addi	sp,sp,-48
    80005ac4:	f406                	sd	ra,40(sp)
    80005ac6:	f022                	sd	s0,32(sp)
    80005ac8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005aca:	fd840593          	addi	a1,s0,-40
    80005ace:	4505                	li	a0,1
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	702080e7          	jalr	1794(ra) # 800031d2 <argaddr>
  argint(2, &n);
    80005ad8:	fe440593          	addi	a1,s0,-28
    80005adc:	4509                	li	a0,2
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	6d4080e7          	jalr	1748(ra) # 800031b2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ae6:	fe840613          	addi	a2,s0,-24
    80005aea:	4581                	li	a1,0
    80005aec:	4501                	li	a0,0
    80005aee:	00000097          	auipc	ra,0x0
    80005af2:	d54080e7          	jalr	-684(ra) # 80005842 <argfd>
    80005af6:	87aa                	mv	a5,a0
    return -1;
    80005af8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005afa:	0007cc63          	bltz	a5,80005b12 <sys_read+0x50>
  return fileread(f, p, n);
    80005afe:	fe442603          	lw	a2,-28(s0)
    80005b02:	fd843583          	ld	a1,-40(s0)
    80005b06:	fe843503          	ld	a0,-24(s0)
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	3d8080e7          	jalr	984(ra) # 80004ee2 <fileread>
}
    80005b12:	70a2                	ld	ra,40(sp)
    80005b14:	7402                	ld	s0,32(sp)
    80005b16:	6145                	addi	sp,sp,48
    80005b18:	8082                	ret

0000000080005b1a <sys_write>:
{
    80005b1a:	7179                	addi	sp,sp,-48
    80005b1c:	f406                	sd	ra,40(sp)
    80005b1e:	f022                	sd	s0,32(sp)
    80005b20:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005b22:	fd840593          	addi	a1,s0,-40
    80005b26:	4505                	li	a0,1
    80005b28:	ffffd097          	auipc	ra,0xffffd
    80005b2c:	6aa080e7          	jalr	1706(ra) # 800031d2 <argaddr>
  argint(2, &n);
    80005b30:	fe440593          	addi	a1,s0,-28
    80005b34:	4509                	li	a0,2
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	67c080e7          	jalr	1660(ra) # 800031b2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005b3e:	fe840613          	addi	a2,s0,-24
    80005b42:	4581                	li	a1,0
    80005b44:	4501                	li	a0,0
    80005b46:	00000097          	auipc	ra,0x0
    80005b4a:	cfc080e7          	jalr	-772(ra) # 80005842 <argfd>
    80005b4e:	87aa                	mv	a5,a0
    return -1;
    80005b50:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b52:	0007cc63          	bltz	a5,80005b6a <sys_write+0x50>
  return filewrite(f, p, n);
    80005b56:	fe442603          	lw	a2,-28(s0)
    80005b5a:	fd843583          	ld	a1,-40(s0)
    80005b5e:	fe843503          	ld	a0,-24(s0)
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	452080e7          	jalr	1106(ra) # 80004fb4 <filewrite>
}
    80005b6a:	70a2                	ld	ra,40(sp)
    80005b6c:	7402                	ld	s0,32(sp)
    80005b6e:	6145                	addi	sp,sp,48
    80005b70:	8082                	ret

0000000080005b72 <sys_close>:
{
    80005b72:	1101                	addi	sp,sp,-32
    80005b74:	ec06                	sd	ra,24(sp)
    80005b76:	e822                	sd	s0,16(sp)
    80005b78:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b7a:	fe040613          	addi	a2,s0,-32
    80005b7e:	fec40593          	addi	a1,s0,-20
    80005b82:	4501                	li	a0,0
    80005b84:	00000097          	auipc	ra,0x0
    80005b88:	cbe080e7          	jalr	-834(ra) # 80005842 <argfd>
    return -1;
    80005b8c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b8e:	02054563          	bltz	a0,80005bb8 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	ee8080e7          	jalr	-280(ra) # 80001a7a <myproc>
    80005b9a:	fec42783          	lw	a5,-20(s0)
    80005b9e:	05478793          	addi	a5,a5,84
    80005ba2:	078e                	slli	a5,a5,0x3
    80005ba4:	953e                	add	a0,a0,a5
    80005ba6:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005baa:	fe043503          	ld	a0,-32(s0)
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	1e0080e7          	jalr	480(ra) # 80004d8e <fileclose>
  return 0;
    80005bb6:	4781                	li	a5,0
}
    80005bb8:	853e                	mv	a0,a5
    80005bba:	60e2                	ld	ra,24(sp)
    80005bbc:	6442                	ld	s0,16(sp)
    80005bbe:	6105                	addi	sp,sp,32
    80005bc0:	8082                	ret

0000000080005bc2 <sys_fstat>:
{
    80005bc2:	1101                	addi	sp,sp,-32
    80005bc4:	ec06                	sd	ra,24(sp)
    80005bc6:	e822                	sd	s0,16(sp)
    80005bc8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005bca:	fe040593          	addi	a1,s0,-32
    80005bce:	4505                	li	a0,1
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	602080e7          	jalr	1538(ra) # 800031d2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005bd8:	fe840613          	addi	a2,s0,-24
    80005bdc:	4581                	li	a1,0
    80005bde:	4501                	li	a0,0
    80005be0:	00000097          	auipc	ra,0x0
    80005be4:	c62080e7          	jalr	-926(ra) # 80005842 <argfd>
    80005be8:	87aa                	mv	a5,a0
    return -1;
    80005bea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005bec:	0007ca63          	bltz	a5,80005c00 <sys_fstat+0x3e>
  return filestat(f, st);
    80005bf0:	fe043583          	ld	a1,-32(s0)
    80005bf4:	fe843503          	ld	a0,-24(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	278080e7          	jalr	632(ra) # 80004e70 <filestat>
}
    80005c00:	60e2                	ld	ra,24(sp)
    80005c02:	6442                	ld	s0,16(sp)
    80005c04:	6105                	addi	sp,sp,32
    80005c06:	8082                	ret

0000000080005c08 <sys_link>:
{
    80005c08:	7169                	addi	sp,sp,-304
    80005c0a:	f606                	sd	ra,296(sp)
    80005c0c:	f222                	sd	s0,288(sp)
    80005c0e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c10:	08000613          	li	a2,128
    80005c14:	ed040593          	addi	a1,s0,-304
    80005c18:	4501                	li	a0,0
    80005c1a:	ffffd097          	auipc	ra,0xffffd
    80005c1e:	5d8080e7          	jalr	1496(ra) # 800031f2 <argstr>
    return -1;
    80005c22:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c24:	12054663          	bltz	a0,80005d50 <sys_link+0x148>
    80005c28:	08000613          	li	a2,128
    80005c2c:	f5040593          	addi	a1,s0,-176
    80005c30:	4505                	li	a0,1
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	5c0080e7          	jalr	1472(ra) # 800031f2 <argstr>
    return -1;
    80005c3a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c3c:	10054a63          	bltz	a0,80005d50 <sys_link+0x148>
    80005c40:	ee26                	sd	s1,280(sp)
  begin_op();
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	c82080e7          	jalr	-894(ra) # 800048c4 <begin_op>
  if((ip = namei(old)) == 0){
    80005c4a:	ed040513          	addi	a0,s0,-304
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	a76080e7          	jalr	-1418(ra) # 800046c4 <namei>
    80005c56:	84aa                	mv	s1,a0
    80005c58:	c949                	beqz	a0,80005cea <sys_link+0xe2>
  ilock(ip);
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	29c080e7          	jalr	668(ra) # 80003ef6 <ilock>
  if(ip->type == T_DIR){
    80005c62:	04449703          	lh	a4,68(s1)
    80005c66:	4785                	li	a5,1
    80005c68:	08f70863          	beq	a4,a5,80005cf8 <sys_link+0xf0>
    80005c6c:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005c6e:	04a4d783          	lhu	a5,74(s1)
    80005c72:	2785                	addiw	a5,a5,1
    80005c74:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c78:	8526                	mv	a0,s1
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	1b0080e7          	jalr	432(ra) # 80003e2a <iupdate>
  iunlock(ip);
    80005c82:	8526                	mv	a0,s1
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	338080e7          	jalr	824(ra) # 80003fbc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c8c:	fd040593          	addi	a1,s0,-48
    80005c90:	f5040513          	addi	a0,s0,-176
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	a4e080e7          	jalr	-1458(ra) # 800046e2 <nameiparent>
    80005c9c:	892a                	mv	s2,a0
    80005c9e:	cd35                	beqz	a0,80005d1a <sys_link+0x112>
  ilock(dp);
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	256080e7          	jalr	598(ra) # 80003ef6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ca8:	00092703          	lw	a4,0(s2)
    80005cac:	409c                	lw	a5,0(s1)
    80005cae:	06f71163          	bne	a4,a5,80005d10 <sys_link+0x108>
    80005cb2:	40d0                	lw	a2,4(s1)
    80005cb4:	fd040593          	addi	a1,s0,-48
    80005cb8:	854a                	mv	a0,s2
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	958080e7          	jalr	-1704(ra) # 80004612 <dirlink>
    80005cc2:	04054763          	bltz	a0,80005d10 <sys_link+0x108>
  iunlockput(dp);
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	494080e7          	jalr	1172(ra) # 8000415c <iunlockput>
  iput(ip);
    80005cd0:	8526                	mv	a0,s1
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	3e2080e7          	jalr	994(ra) # 800040b4 <iput>
  end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	c64080e7          	jalr	-924(ra) # 8000493e <end_op>
  return 0;
    80005ce2:	4781                	li	a5,0
    80005ce4:	64f2                	ld	s1,280(sp)
    80005ce6:	6952                	ld	s2,272(sp)
    80005ce8:	a0a5                	j	80005d50 <sys_link+0x148>
    end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	c54080e7          	jalr	-940(ra) # 8000493e <end_op>
    return -1;
    80005cf2:	57fd                	li	a5,-1
    80005cf4:	64f2                	ld	s1,280(sp)
    80005cf6:	a8a9                	j	80005d50 <sys_link+0x148>
    iunlockput(ip);
    80005cf8:	8526                	mv	a0,s1
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	462080e7          	jalr	1122(ra) # 8000415c <iunlockput>
    end_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	c3c080e7          	jalr	-964(ra) # 8000493e <end_op>
    return -1;
    80005d0a:	57fd                	li	a5,-1
    80005d0c:	64f2                	ld	s1,280(sp)
    80005d0e:	a089                	j	80005d50 <sys_link+0x148>
    iunlockput(dp);
    80005d10:	854a                	mv	a0,s2
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	44a080e7          	jalr	1098(ra) # 8000415c <iunlockput>
  ilock(ip);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	1da080e7          	jalr	474(ra) # 80003ef6 <ilock>
  ip->nlink--;
    80005d24:	04a4d783          	lhu	a5,74(s1)
    80005d28:	37fd                	addiw	a5,a5,-1
    80005d2a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d2e:	8526                	mv	a0,s1
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	0fa080e7          	jalr	250(ra) # 80003e2a <iupdate>
  iunlockput(ip);
    80005d38:	8526                	mv	a0,s1
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	422080e7          	jalr	1058(ra) # 8000415c <iunlockput>
  end_op();
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	bfc080e7          	jalr	-1028(ra) # 8000493e <end_op>
  return -1;
    80005d4a:	57fd                	li	a5,-1
    80005d4c:	64f2                	ld	s1,280(sp)
    80005d4e:	6952                	ld	s2,272(sp)
}
    80005d50:	853e                	mv	a0,a5
    80005d52:	70b2                	ld	ra,296(sp)
    80005d54:	7412                	ld	s0,288(sp)
    80005d56:	6155                	addi	sp,sp,304
    80005d58:	8082                	ret

0000000080005d5a <sys_unlink>:
{
    80005d5a:	7151                	addi	sp,sp,-240
    80005d5c:	f586                	sd	ra,232(sp)
    80005d5e:	f1a2                	sd	s0,224(sp)
    80005d60:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d62:	08000613          	li	a2,128
    80005d66:	f3040593          	addi	a1,s0,-208
    80005d6a:	4501                	li	a0,0
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	486080e7          	jalr	1158(ra) # 800031f2 <argstr>
    80005d74:	1a054a63          	bltz	a0,80005f28 <sys_unlink+0x1ce>
    80005d78:	eda6                	sd	s1,216(sp)
  begin_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	b4a080e7          	jalr	-1206(ra) # 800048c4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d82:	fb040593          	addi	a1,s0,-80
    80005d86:	f3040513          	addi	a0,s0,-208
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	958080e7          	jalr	-1704(ra) # 800046e2 <nameiparent>
    80005d92:	84aa                	mv	s1,a0
    80005d94:	cd71                	beqz	a0,80005e70 <sys_unlink+0x116>
  ilock(dp);
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	160080e7          	jalr	352(ra) # 80003ef6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d9e:	00003597          	auipc	a1,0x3
    80005da2:	83a58593          	addi	a1,a1,-1990 # 800085d8 <etext+0x5d8>
    80005da6:	fb040513          	addi	a0,s0,-80
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	63e080e7          	jalr	1598(ra) # 800043e8 <namecmp>
    80005db2:	14050c63          	beqz	a0,80005f0a <sys_unlink+0x1b0>
    80005db6:	00003597          	auipc	a1,0x3
    80005dba:	82a58593          	addi	a1,a1,-2006 # 800085e0 <etext+0x5e0>
    80005dbe:	fb040513          	addi	a0,s0,-80
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	626080e7          	jalr	1574(ra) # 800043e8 <namecmp>
    80005dca:	14050063          	beqz	a0,80005f0a <sys_unlink+0x1b0>
    80005dce:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dd0:	f2c40613          	addi	a2,s0,-212
    80005dd4:	fb040593          	addi	a1,s0,-80
    80005dd8:	8526                	mv	a0,s1
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	628080e7          	jalr	1576(ra) # 80004402 <dirlookup>
    80005de2:	892a                	mv	s2,a0
    80005de4:	12050263          	beqz	a0,80005f08 <sys_unlink+0x1ae>
  ilock(ip);
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	10e080e7          	jalr	270(ra) # 80003ef6 <ilock>
  if(ip->nlink < 1)
    80005df0:	04a91783          	lh	a5,74(s2)
    80005df4:	08f05563          	blez	a5,80005e7e <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005df8:	04491703          	lh	a4,68(s2)
    80005dfc:	4785                	li	a5,1
    80005dfe:	08f70963          	beq	a4,a5,80005e90 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80005e02:	4641                	li	a2,16
    80005e04:	4581                	li	a1,0
    80005e06:	fc040513          	addi	a0,s0,-64
    80005e0a:	ffffb097          	auipc	ra,0xffffb
    80005e0e:	f2a080e7          	jalr	-214(ra) # 80000d34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e12:	4741                	li	a4,16
    80005e14:	f2c42683          	lw	a3,-212(s0)
    80005e18:	fc040613          	addi	a2,s0,-64
    80005e1c:	4581                	li	a1,0
    80005e1e:	8526                	mv	a0,s1
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	49e080e7          	jalr	1182(ra) # 800042be <writei>
    80005e28:	47c1                	li	a5,16
    80005e2a:	0af51b63          	bne	a0,a5,80005ee0 <sys_unlink+0x186>
  if(ip->type == T_DIR){
    80005e2e:	04491703          	lh	a4,68(s2)
    80005e32:	4785                	li	a5,1
    80005e34:	0af70f63          	beq	a4,a5,80005ef2 <sys_unlink+0x198>
  iunlockput(dp);
    80005e38:	8526                	mv	a0,s1
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	322080e7          	jalr	802(ra) # 8000415c <iunlockput>
  ip->nlink--;
    80005e42:	04a95783          	lhu	a5,74(s2)
    80005e46:	37fd                	addiw	a5,a5,-1
    80005e48:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e4c:	854a                	mv	a0,s2
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	fdc080e7          	jalr	-36(ra) # 80003e2a <iupdate>
  iunlockput(ip);
    80005e56:	854a                	mv	a0,s2
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	304080e7          	jalr	772(ra) # 8000415c <iunlockput>
  end_op();
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	ade080e7          	jalr	-1314(ra) # 8000493e <end_op>
  return 0;
    80005e68:	4501                	li	a0,0
    80005e6a:	64ee                	ld	s1,216(sp)
    80005e6c:	694e                	ld	s2,208(sp)
    80005e6e:	a84d                	j	80005f20 <sys_unlink+0x1c6>
    end_op();
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	ace080e7          	jalr	-1330(ra) # 8000493e <end_op>
    return -1;
    80005e78:	557d                	li	a0,-1
    80005e7a:	64ee                	ld	s1,216(sp)
    80005e7c:	a055                	j	80005f20 <sys_unlink+0x1c6>
    80005e7e:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005e80:	00002517          	auipc	a0,0x2
    80005e84:	76850513          	addi	a0,a0,1896 # 800085e8 <etext+0x5e8>
    80005e88:	ffffa097          	auipc	ra,0xffffa
    80005e8c:	6d8080e7          	jalr	1752(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e90:	04c92703          	lw	a4,76(s2)
    80005e94:	02000793          	li	a5,32
    80005e98:	f6e7f5e3          	bgeu	a5,a4,80005e02 <sys_unlink+0xa8>
    80005e9c:	e5ce                	sd	s3,200(sp)
    80005e9e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ea2:	4741                	li	a4,16
    80005ea4:	86ce                	mv	a3,s3
    80005ea6:	f1840613          	addi	a2,s0,-232
    80005eaa:	4581                	li	a1,0
    80005eac:	854a                	mv	a0,s2
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	300080e7          	jalr	768(ra) # 800041ae <readi>
    80005eb6:	47c1                	li	a5,16
    80005eb8:	00f51c63          	bne	a0,a5,80005ed0 <sys_unlink+0x176>
    if(de.inum != 0)
    80005ebc:	f1845783          	lhu	a5,-232(s0)
    80005ec0:	e7b5                	bnez	a5,80005f2c <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ec2:	29c1                	addiw	s3,s3,16
    80005ec4:	04c92783          	lw	a5,76(s2)
    80005ec8:	fcf9ede3          	bltu	s3,a5,80005ea2 <sys_unlink+0x148>
    80005ecc:	69ae                	ld	s3,200(sp)
    80005ece:	bf15                	j	80005e02 <sys_unlink+0xa8>
      panic("isdirempty: readi");
    80005ed0:	00002517          	auipc	a0,0x2
    80005ed4:	73050513          	addi	a0,a0,1840 # 80008600 <etext+0x600>
    80005ed8:	ffffa097          	auipc	ra,0xffffa
    80005edc:	688080e7          	jalr	1672(ra) # 80000560 <panic>
    80005ee0:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005ee2:	00002517          	auipc	a0,0x2
    80005ee6:	73650513          	addi	a0,a0,1846 # 80008618 <etext+0x618>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	676080e7          	jalr	1654(ra) # 80000560 <panic>
    dp->nlink--;
    80005ef2:	04a4d783          	lhu	a5,74(s1)
    80005ef6:	37fd                	addiw	a5,a5,-1
    80005ef8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005efc:	8526                	mv	a0,s1
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	f2c080e7          	jalr	-212(ra) # 80003e2a <iupdate>
    80005f06:	bf0d                	j	80005e38 <sys_unlink+0xde>
    80005f08:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005f0a:	8526                	mv	a0,s1
    80005f0c:	ffffe097          	auipc	ra,0xffffe
    80005f10:	250080e7          	jalr	592(ra) # 8000415c <iunlockput>
  end_op();
    80005f14:	fffff097          	auipc	ra,0xfffff
    80005f18:	a2a080e7          	jalr	-1494(ra) # 8000493e <end_op>
  return -1;
    80005f1c:	557d                	li	a0,-1
    80005f1e:	64ee                	ld	s1,216(sp)
}
    80005f20:	70ae                	ld	ra,232(sp)
    80005f22:	740e                	ld	s0,224(sp)
    80005f24:	616d                	addi	sp,sp,240
    80005f26:	8082                	ret
    return -1;
    80005f28:	557d                	li	a0,-1
    80005f2a:	bfdd                	j	80005f20 <sys_unlink+0x1c6>
    iunlockput(ip);
    80005f2c:	854a                	mv	a0,s2
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	22e080e7          	jalr	558(ra) # 8000415c <iunlockput>
    goto bad;
    80005f36:	694e                	ld	s2,208(sp)
    80005f38:	69ae                	ld	s3,200(sp)
    80005f3a:	bfc1                	j	80005f0a <sys_unlink+0x1b0>

0000000080005f3c <sys_open>:

uint64
sys_open(void)
{
    80005f3c:	7131                	addi	sp,sp,-192
    80005f3e:	fd06                	sd	ra,184(sp)
    80005f40:	f922                	sd	s0,176(sp)
    80005f42:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005f44:	f4c40593          	addi	a1,s0,-180
    80005f48:	4505                	li	a0,1
    80005f4a:	ffffd097          	auipc	ra,0xffffd
    80005f4e:	268080e7          	jalr	616(ra) # 800031b2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f52:	08000613          	li	a2,128
    80005f56:	f5040593          	addi	a1,s0,-176
    80005f5a:	4501                	li	a0,0
    80005f5c:	ffffd097          	auipc	ra,0xffffd
    80005f60:	296080e7          	jalr	662(ra) # 800031f2 <argstr>
    80005f64:	87aa                	mv	a5,a0
    return -1;
    80005f66:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f68:	0a07ce63          	bltz	a5,80006024 <sys_open+0xe8>
    80005f6c:	f526                	sd	s1,168(sp)

  begin_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	956080e7          	jalr	-1706(ra) # 800048c4 <begin_op>

  if(omode & O_CREATE){
    80005f76:	f4c42783          	lw	a5,-180(s0)
    80005f7a:	2007f793          	andi	a5,a5,512
    80005f7e:	cfd5                	beqz	a5,8000603a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f80:	4681                	li	a3,0
    80005f82:	4601                	li	a2,0
    80005f84:	4589                	li	a1,2
    80005f86:	f5040513          	addi	a0,s0,-176
    80005f8a:	00000097          	auipc	ra,0x0
    80005f8e:	95a080e7          	jalr	-1702(ra) # 800058e4 <create>
    80005f92:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f94:	cd41                	beqz	a0,8000602c <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f96:	04449703          	lh	a4,68(s1)
    80005f9a:	478d                	li	a5,3
    80005f9c:	00f71763          	bne	a4,a5,80005faa <sys_open+0x6e>
    80005fa0:	0464d703          	lhu	a4,70(s1)
    80005fa4:	47a5                	li	a5,9
    80005fa6:	0ee7e163          	bltu	a5,a4,80006088 <sys_open+0x14c>
    80005faa:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	d26080e7          	jalr	-730(ra) # 80004cd2 <filealloc>
    80005fb4:	892a                	mv	s2,a0
    80005fb6:	c97d                	beqz	a0,800060ac <sys_open+0x170>
    80005fb8:	ed4e                	sd	s3,152(sp)
    80005fba:	00000097          	auipc	ra,0x0
    80005fbe:	8e8080e7          	jalr	-1816(ra) # 800058a2 <fdalloc>
    80005fc2:	89aa                	mv	s3,a0
    80005fc4:	0c054e63          	bltz	a0,800060a0 <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fc8:	04449703          	lh	a4,68(s1)
    80005fcc:	478d                	li	a5,3
    80005fce:	0ef70c63          	beq	a4,a5,800060c6 <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fd2:	4789                	li	a5,2
    80005fd4:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005fd8:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005fdc:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005fe0:	f4c42783          	lw	a5,-180(s0)
    80005fe4:	0017c713          	xori	a4,a5,1
    80005fe8:	8b05                	andi	a4,a4,1
    80005fea:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005fee:	0037f713          	andi	a4,a5,3
    80005ff2:	00e03733          	snez	a4,a4
    80005ff6:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ffa:	4007f793          	andi	a5,a5,1024
    80005ffe:	c791                	beqz	a5,8000600a <sys_open+0xce>
    80006000:	04449703          	lh	a4,68(s1)
    80006004:	4789                	li	a5,2
    80006006:	0cf70763          	beq	a4,a5,800060d4 <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    8000600a:	8526                	mv	a0,s1
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	fb0080e7          	jalr	-80(ra) # 80003fbc <iunlock>
  end_op();
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	92a080e7          	jalr	-1750(ra) # 8000493e <end_op>

  return fd;
    8000601c:	854e                	mv	a0,s3
    8000601e:	74aa                	ld	s1,168(sp)
    80006020:	790a                	ld	s2,160(sp)
    80006022:	69ea                	ld	s3,152(sp)
}
    80006024:	70ea                	ld	ra,184(sp)
    80006026:	744a                	ld	s0,176(sp)
    80006028:	6129                	addi	sp,sp,192
    8000602a:	8082                	ret
      end_op();
    8000602c:	fffff097          	auipc	ra,0xfffff
    80006030:	912080e7          	jalr	-1774(ra) # 8000493e <end_op>
      return -1;
    80006034:	557d                	li	a0,-1
    80006036:	74aa                	ld	s1,168(sp)
    80006038:	b7f5                	j	80006024 <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    8000603a:	f5040513          	addi	a0,s0,-176
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	686080e7          	jalr	1670(ra) # 800046c4 <namei>
    80006046:	84aa                	mv	s1,a0
    80006048:	c90d                	beqz	a0,8000607a <sys_open+0x13e>
    ilock(ip);
    8000604a:	ffffe097          	auipc	ra,0xffffe
    8000604e:	eac080e7          	jalr	-340(ra) # 80003ef6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006052:	04449703          	lh	a4,68(s1)
    80006056:	4785                	li	a5,1
    80006058:	f2f71fe3          	bne	a4,a5,80005f96 <sys_open+0x5a>
    8000605c:	f4c42783          	lw	a5,-180(s0)
    80006060:	d7a9                	beqz	a5,80005faa <sys_open+0x6e>
      iunlockput(ip);
    80006062:	8526                	mv	a0,s1
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	0f8080e7          	jalr	248(ra) # 8000415c <iunlockput>
      end_op();
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	8d2080e7          	jalr	-1838(ra) # 8000493e <end_op>
      return -1;
    80006074:	557d                	li	a0,-1
    80006076:	74aa                	ld	s1,168(sp)
    80006078:	b775                	j	80006024 <sys_open+0xe8>
      end_op();
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	8c4080e7          	jalr	-1852(ra) # 8000493e <end_op>
      return -1;
    80006082:	557d                	li	a0,-1
    80006084:	74aa                	ld	s1,168(sp)
    80006086:	bf79                	j	80006024 <sys_open+0xe8>
    iunlockput(ip);
    80006088:	8526                	mv	a0,s1
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	0d2080e7          	jalr	210(ra) # 8000415c <iunlockput>
    end_op();
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	8ac080e7          	jalr	-1876(ra) # 8000493e <end_op>
    return -1;
    8000609a:	557d                	li	a0,-1
    8000609c:	74aa                	ld	s1,168(sp)
    8000609e:	b759                	j	80006024 <sys_open+0xe8>
      fileclose(f);
    800060a0:	854a                	mv	a0,s2
    800060a2:	fffff097          	auipc	ra,0xfffff
    800060a6:	cec080e7          	jalr	-788(ra) # 80004d8e <fileclose>
    800060aa:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800060ac:	8526                	mv	a0,s1
    800060ae:	ffffe097          	auipc	ra,0xffffe
    800060b2:	0ae080e7          	jalr	174(ra) # 8000415c <iunlockput>
    end_op();
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	888080e7          	jalr	-1912(ra) # 8000493e <end_op>
    return -1;
    800060be:	557d                	li	a0,-1
    800060c0:	74aa                	ld	s1,168(sp)
    800060c2:	790a                	ld	s2,160(sp)
    800060c4:	b785                	j	80006024 <sys_open+0xe8>
    f->type = FD_DEVICE;
    800060c6:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800060ca:	04649783          	lh	a5,70(s1)
    800060ce:	02f91223          	sh	a5,36(s2)
    800060d2:	b729                	j	80005fdc <sys_open+0xa0>
    itrunc(ip);
    800060d4:	8526                	mv	a0,s1
    800060d6:	ffffe097          	auipc	ra,0xffffe
    800060da:	f32080e7          	jalr	-206(ra) # 80004008 <itrunc>
    800060de:	b735                	j	8000600a <sys_open+0xce>

00000000800060e0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060e0:	7175                	addi	sp,sp,-144
    800060e2:	e506                	sd	ra,136(sp)
    800060e4:	e122                	sd	s0,128(sp)
    800060e6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	7dc080e7          	jalr	2012(ra) # 800048c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060f0:	08000613          	li	a2,128
    800060f4:	f7040593          	addi	a1,s0,-144
    800060f8:	4501                	li	a0,0
    800060fa:	ffffd097          	auipc	ra,0xffffd
    800060fe:	0f8080e7          	jalr	248(ra) # 800031f2 <argstr>
    80006102:	02054963          	bltz	a0,80006134 <sys_mkdir+0x54>
    80006106:	4681                	li	a3,0
    80006108:	4601                	li	a2,0
    8000610a:	4585                	li	a1,1
    8000610c:	f7040513          	addi	a0,s0,-144
    80006110:	fffff097          	auipc	ra,0xfffff
    80006114:	7d4080e7          	jalr	2004(ra) # 800058e4 <create>
    80006118:	cd11                	beqz	a0,80006134 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	042080e7          	jalr	66(ra) # 8000415c <iunlockput>
  end_op();
    80006122:	fffff097          	auipc	ra,0xfffff
    80006126:	81c080e7          	jalr	-2020(ra) # 8000493e <end_op>
  return 0;
    8000612a:	4501                	li	a0,0
}
    8000612c:	60aa                	ld	ra,136(sp)
    8000612e:	640a                	ld	s0,128(sp)
    80006130:	6149                	addi	sp,sp,144
    80006132:	8082                	ret
    end_op();
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	80a080e7          	jalr	-2038(ra) # 8000493e <end_op>
    return -1;
    8000613c:	557d                	li	a0,-1
    8000613e:	b7fd                	j	8000612c <sys_mkdir+0x4c>

0000000080006140 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006140:	7135                	addi	sp,sp,-160
    80006142:	ed06                	sd	ra,152(sp)
    80006144:	e922                	sd	s0,144(sp)
    80006146:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	77c080e7          	jalr	1916(ra) # 800048c4 <begin_op>
  argint(1, &major);
    80006150:	f6c40593          	addi	a1,s0,-148
    80006154:	4505                	li	a0,1
    80006156:	ffffd097          	auipc	ra,0xffffd
    8000615a:	05c080e7          	jalr	92(ra) # 800031b2 <argint>
  argint(2, &minor);
    8000615e:	f6840593          	addi	a1,s0,-152
    80006162:	4509                	li	a0,2
    80006164:	ffffd097          	auipc	ra,0xffffd
    80006168:	04e080e7          	jalr	78(ra) # 800031b2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000616c:	08000613          	li	a2,128
    80006170:	f7040593          	addi	a1,s0,-144
    80006174:	4501                	li	a0,0
    80006176:	ffffd097          	auipc	ra,0xffffd
    8000617a:	07c080e7          	jalr	124(ra) # 800031f2 <argstr>
    8000617e:	02054b63          	bltz	a0,800061b4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006182:	f6841683          	lh	a3,-152(s0)
    80006186:	f6c41603          	lh	a2,-148(s0)
    8000618a:	458d                	li	a1,3
    8000618c:	f7040513          	addi	a0,s0,-144
    80006190:	fffff097          	auipc	ra,0xfffff
    80006194:	754080e7          	jalr	1876(ra) # 800058e4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006198:	cd11                	beqz	a0,800061b4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	fc2080e7          	jalr	-62(ra) # 8000415c <iunlockput>
  end_op();
    800061a2:	ffffe097          	auipc	ra,0xffffe
    800061a6:	79c080e7          	jalr	1948(ra) # 8000493e <end_op>
  return 0;
    800061aa:	4501                	li	a0,0
}
    800061ac:	60ea                	ld	ra,152(sp)
    800061ae:	644a                	ld	s0,144(sp)
    800061b0:	610d                	addi	sp,sp,160
    800061b2:	8082                	ret
    end_op();
    800061b4:	ffffe097          	auipc	ra,0xffffe
    800061b8:	78a080e7          	jalr	1930(ra) # 8000493e <end_op>
    return -1;
    800061bc:	557d                	li	a0,-1
    800061be:	b7fd                	j	800061ac <sys_mknod+0x6c>

00000000800061c0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800061c0:	7135                	addi	sp,sp,-160
    800061c2:	ed06                	sd	ra,152(sp)
    800061c4:	e922                	sd	s0,144(sp)
    800061c6:	e14a                	sd	s2,128(sp)
    800061c8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061ca:	ffffc097          	auipc	ra,0xffffc
    800061ce:	8b0080e7          	jalr	-1872(ra) # 80001a7a <myproc>
    800061d2:	892a                	mv	s2,a0
  
  begin_op();
    800061d4:	ffffe097          	auipc	ra,0xffffe
    800061d8:	6f0080e7          	jalr	1776(ra) # 800048c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061dc:	08000613          	li	a2,128
    800061e0:	f6040593          	addi	a1,s0,-160
    800061e4:	4501                	li	a0,0
    800061e6:	ffffd097          	auipc	ra,0xffffd
    800061ea:	00c080e7          	jalr	12(ra) # 800031f2 <argstr>
    800061ee:	04054d63          	bltz	a0,80006248 <sys_chdir+0x88>
    800061f2:	e526                	sd	s1,136(sp)
    800061f4:	f6040513          	addi	a0,s0,-160
    800061f8:	ffffe097          	auipc	ra,0xffffe
    800061fc:	4cc080e7          	jalr	1228(ra) # 800046c4 <namei>
    80006200:	84aa                	mv	s1,a0
    80006202:	c131                	beqz	a0,80006246 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006204:	ffffe097          	auipc	ra,0xffffe
    80006208:	cf2080e7          	jalr	-782(ra) # 80003ef6 <ilock>
  if(ip->type != T_DIR){
    8000620c:	04449703          	lh	a4,68(s1)
    80006210:	4785                	li	a5,1
    80006212:	04f71163          	bne	a4,a5,80006254 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006216:	8526                	mv	a0,s1
    80006218:	ffffe097          	auipc	ra,0xffffe
    8000621c:	da4080e7          	jalr	-604(ra) # 80003fbc <iunlock>
  iput(p->cwd);
    80006220:	32893503          	ld	a0,808(s2)
    80006224:	ffffe097          	auipc	ra,0xffffe
    80006228:	e90080e7          	jalr	-368(ra) # 800040b4 <iput>
  end_op();
    8000622c:	ffffe097          	auipc	ra,0xffffe
    80006230:	712080e7          	jalr	1810(ra) # 8000493e <end_op>
  p->cwd = ip;
    80006234:	32993423          	sd	s1,808(s2)
  return 0;
    80006238:	4501                	li	a0,0
    8000623a:	64aa                	ld	s1,136(sp)
}
    8000623c:	60ea                	ld	ra,152(sp)
    8000623e:	644a                	ld	s0,144(sp)
    80006240:	690a                	ld	s2,128(sp)
    80006242:	610d                	addi	sp,sp,160
    80006244:	8082                	ret
    80006246:	64aa                	ld	s1,136(sp)
    end_op();
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	6f6080e7          	jalr	1782(ra) # 8000493e <end_op>
    return -1;
    80006250:	557d                	li	a0,-1
    80006252:	b7ed                	j	8000623c <sys_chdir+0x7c>
    iunlockput(ip);
    80006254:	8526                	mv	a0,s1
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	f06080e7          	jalr	-250(ra) # 8000415c <iunlockput>
    end_op();
    8000625e:	ffffe097          	auipc	ra,0xffffe
    80006262:	6e0080e7          	jalr	1760(ra) # 8000493e <end_op>
    return -1;
    80006266:	557d                	li	a0,-1
    80006268:	64aa                	ld	s1,136(sp)
    8000626a:	bfc9                	j	8000623c <sys_chdir+0x7c>

000000008000626c <sys_exec>:

uint64
sys_exec(void)
{
    8000626c:	7121                	addi	sp,sp,-448
    8000626e:	ff06                	sd	ra,440(sp)
    80006270:	fb22                	sd	s0,432(sp)
    80006272:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006274:	e4840593          	addi	a1,s0,-440
    80006278:	4505                	li	a0,1
    8000627a:	ffffd097          	auipc	ra,0xffffd
    8000627e:	f58080e7          	jalr	-168(ra) # 800031d2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006282:	08000613          	li	a2,128
    80006286:	f5040593          	addi	a1,s0,-176
    8000628a:	4501                	li	a0,0
    8000628c:	ffffd097          	auipc	ra,0xffffd
    80006290:	f66080e7          	jalr	-154(ra) # 800031f2 <argstr>
    80006294:	87aa                	mv	a5,a0
    return -1;
    80006296:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006298:	0e07c263          	bltz	a5,8000637c <sys_exec+0x110>
    8000629c:	f726                	sd	s1,424(sp)
    8000629e:	f34a                	sd	s2,416(sp)
    800062a0:	ef4e                	sd	s3,408(sp)
    800062a2:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800062a4:	10000613          	li	a2,256
    800062a8:	4581                	li	a1,0
    800062aa:	e5040513          	addi	a0,s0,-432
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	a86080e7          	jalr	-1402(ra) # 80000d34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062b6:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800062ba:	89a6                	mv	s3,s1
    800062bc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062be:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062c2:	00391513          	slli	a0,s2,0x3
    800062c6:	e4040593          	addi	a1,s0,-448
    800062ca:	e4843783          	ld	a5,-440(s0)
    800062ce:	953e                	add	a0,a0,a5
    800062d0:	ffffd097          	auipc	ra,0xffffd
    800062d4:	e3e080e7          	jalr	-450(ra) # 8000310e <fetchaddr>
    800062d8:	02054a63          	bltz	a0,8000630c <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800062dc:	e4043783          	ld	a5,-448(s0)
    800062e0:	c7b9                	beqz	a5,8000632e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062e2:	ffffb097          	auipc	ra,0xffffb
    800062e6:	866080e7          	jalr	-1946(ra) # 80000b48 <kalloc>
    800062ea:	85aa                	mv	a1,a0
    800062ec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062f0:	cd11                	beqz	a0,8000630c <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062f2:	6605                	lui	a2,0x1
    800062f4:	e4043503          	ld	a0,-448(s0)
    800062f8:	ffffd097          	auipc	ra,0xffffd
    800062fc:	e6c080e7          	jalr	-404(ra) # 80003164 <fetchstr>
    80006300:	00054663          	bltz	a0,8000630c <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006304:	0905                	addi	s2,s2,1
    80006306:	09a1                	addi	s3,s3,8
    80006308:	fb491de3          	bne	s2,s4,800062c2 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000630c:	f5040913          	addi	s2,s0,-176
    80006310:	6088                	ld	a0,0(s1)
    80006312:	c125                	beqz	a0,80006372 <sys_exec+0x106>
    kfree(argv[i]);
    80006314:	ffffa097          	auipc	ra,0xffffa
    80006318:	736080e7          	jalr	1846(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000631c:	04a1                	addi	s1,s1,8
    8000631e:	ff2499e3          	bne	s1,s2,80006310 <sys_exec+0xa4>
  return -1;
    80006322:	557d                	li	a0,-1
    80006324:	74ba                	ld	s1,424(sp)
    80006326:	791a                	ld	s2,416(sp)
    80006328:	69fa                	ld	s3,408(sp)
    8000632a:	6a5a                	ld	s4,400(sp)
    8000632c:	a881                	j	8000637c <sys_exec+0x110>
      argv[i] = 0;
    8000632e:	0009079b          	sext.w	a5,s2
    80006332:	078e                	slli	a5,a5,0x3
    80006334:	fd078793          	addi	a5,a5,-48
    80006338:	97a2                	add	a5,a5,s0
    8000633a:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    8000633e:	e5040593          	addi	a1,s0,-432
    80006342:	f5040513          	addi	a0,s0,-176
    80006346:	fffff097          	auipc	ra,0xfffff
    8000634a:	11e080e7          	jalr	286(ra) # 80005464 <exec>
    8000634e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006350:	f5040993          	addi	s3,s0,-176
    80006354:	6088                	ld	a0,0(s1)
    80006356:	c901                	beqz	a0,80006366 <sys_exec+0xfa>
    kfree(argv[i]);
    80006358:	ffffa097          	auipc	ra,0xffffa
    8000635c:	6f2080e7          	jalr	1778(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006360:	04a1                	addi	s1,s1,8
    80006362:	ff3499e3          	bne	s1,s3,80006354 <sys_exec+0xe8>
  return ret;
    80006366:	854a                	mv	a0,s2
    80006368:	74ba                	ld	s1,424(sp)
    8000636a:	791a                	ld	s2,416(sp)
    8000636c:	69fa                	ld	s3,408(sp)
    8000636e:	6a5a                	ld	s4,400(sp)
    80006370:	a031                	j	8000637c <sys_exec+0x110>
  return -1;
    80006372:	557d                	li	a0,-1
    80006374:	74ba                	ld	s1,424(sp)
    80006376:	791a                	ld	s2,416(sp)
    80006378:	69fa                	ld	s3,408(sp)
    8000637a:	6a5a                	ld	s4,400(sp)
}
    8000637c:	70fa                	ld	ra,440(sp)
    8000637e:	745a                	ld	s0,432(sp)
    80006380:	6139                	addi	sp,sp,448
    80006382:	8082                	ret

0000000080006384 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006384:	7139                	addi	sp,sp,-64
    80006386:	fc06                	sd	ra,56(sp)
    80006388:	f822                	sd	s0,48(sp)
    8000638a:	f426                	sd	s1,40(sp)
    8000638c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000638e:	ffffb097          	auipc	ra,0xffffb
    80006392:	6ec080e7          	jalr	1772(ra) # 80001a7a <myproc>
    80006396:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006398:	fd840593          	addi	a1,s0,-40
    8000639c:	4501                	li	a0,0
    8000639e:	ffffd097          	auipc	ra,0xffffd
    800063a2:	e34080e7          	jalr	-460(ra) # 800031d2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800063a6:	fc840593          	addi	a1,s0,-56
    800063aa:	fd040513          	addi	a0,s0,-48
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	d4e080e7          	jalr	-690(ra) # 800050fc <pipealloc>
    return -1;
    800063b6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063b8:	0c054963          	bltz	a0,8000648a <sys_pipe+0x106>
  fd0 = -1;
    800063bc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063c0:	fd043503          	ld	a0,-48(s0)
    800063c4:	fffff097          	auipc	ra,0xfffff
    800063c8:	4de080e7          	jalr	1246(ra) # 800058a2 <fdalloc>
    800063cc:	fca42223          	sw	a0,-60(s0)
    800063d0:	0a054063          	bltz	a0,80006470 <sys_pipe+0xec>
    800063d4:	fc843503          	ld	a0,-56(s0)
    800063d8:	fffff097          	auipc	ra,0xfffff
    800063dc:	4ca080e7          	jalr	1226(ra) # 800058a2 <fdalloc>
    800063e0:	fca42023          	sw	a0,-64(s0)
    800063e4:	06054c63          	bltz	a0,8000645c <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063e8:	4691                	li	a3,4
    800063ea:	fc440613          	addi	a2,s0,-60
    800063ee:	fd843583          	ld	a1,-40(s0)
    800063f2:	2284b503          	ld	a0,552(s1)
    800063f6:	ffffb097          	auipc	ra,0xffffb
    800063fa:	2ec080e7          	jalr	748(ra) # 800016e2 <copyout>
    800063fe:	02054163          	bltz	a0,80006420 <sys_pipe+0x9c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006402:	4691                	li	a3,4
    80006404:	fc040613          	addi	a2,s0,-64
    80006408:	fd843583          	ld	a1,-40(s0)
    8000640c:	0591                	addi	a1,a1,4
    8000640e:	2284b503          	ld	a0,552(s1)
    80006412:	ffffb097          	auipc	ra,0xffffb
    80006416:	2d0080e7          	jalr	720(ra) # 800016e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000641a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000641c:	06055763          	bgez	a0,8000648a <sys_pipe+0x106>
    p->ofile[fd0] = 0;
    80006420:	fc442783          	lw	a5,-60(s0)
    80006424:	05478793          	addi	a5,a5,84
    80006428:	078e                	slli	a5,a5,0x3
    8000642a:	97a6                	add	a5,a5,s1
    8000642c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006430:	fc042783          	lw	a5,-64(s0)
    80006434:	05478793          	addi	a5,a5,84
    80006438:	078e                	slli	a5,a5,0x3
    8000643a:	94be                	add	s1,s1,a5
    8000643c:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80006440:	fd043503          	ld	a0,-48(s0)
    80006444:	fffff097          	auipc	ra,0xfffff
    80006448:	94a080e7          	jalr	-1718(ra) # 80004d8e <fileclose>
    fileclose(wf);
    8000644c:	fc843503          	ld	a0,-56(s0)
    80006450:	fffff097          	auipc	ra,0xfffff
    80006454:	93e080e7          	jalr	-1730(ra) # 80004d8e <fileclose>
    return -1;
    80006458:	57fd                	li	a5,-1
    8000645a:	a805                	j	8000648a <sys_pipe+0x106>
    if(fd0 >= 0)
    8000645c:	fc442783          	lw	a5,-60(s0)
    80006460:	0007c863          	bltz	a5,80006470 <sys_pipe+0xec>
      p->ofile[fd0] = 0;
    80006464:	05478793          	addi	a5,a5,84
    80006468:	078e                	slli	a5,a5,0x3
    8000646a:	97a6                	add	a5,a5,s1
    8000646c:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80006470:	fd043503          	ld	a0,-48(s0)
    80006474:	fffff097          	auipc	ra,0xfffff
    80006478:	91a080e7          	jalr	-1766(ra) # 80004d8e <fileclose>
    fileclose(wf);
    8000647c:	fc843503          	ld	a0,-56(s0)
    80006480:	fffff097          	auipc	ra,0xfffff
    80006484:	90e080e7          	jalr	-1778(ra) # 80004d8e <fileclose>
    return -1;
    80006488:	57fd                	li	a5,-1
}
    8000648a:	853e                	mv	a0,a5
    8000648c:	70e2                	ld	ra,56(sp)
    8000648e:	7442                	ld	s0,48(sp)
    80006490:	74a2                	ld	s1,40(sp)
    80006492:	6121                	addi	sp,sp,64
    80006494:	8082                	ret
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
    8000660c:	35878793          	addi	a5,a5,856 # 8002c960 <disk>
    80006610:	97aa                	add	a5,a5,a0
    80006612:	0187c783          	lbu	a5,24(a5)
    80006616:	ebb9                	bnez	a5,8000666c <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006618:	00451693          	slli	a3,a0,0x4
    8000661c:	00026797          	auipc	a5,0x26
    80006620:	34478793          	addi	a5,a5,836 # 8002c960 <disk>
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
    80006648:	33450513          	addi	a0,a0,820 # 8002c978 <disk+0x18>
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
    80006694:	3f850513          	addi	a0,a0,1016 # 8002ca88 <disk+0x128>
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
    80006700:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd1cbf>
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
    8000675a:	20a48493          	addi	s1,s1,522 # 8002c960 <disk>
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
    80006780:	1ec73703          	ld	a4,492(a4) # 8002c968 <disk+0x8>
    80006784:	10070a63          	beqz	a4,80006898 <virtio_disk_init+0x21c>
    80006788:	10078863          	beqz	a5,80006898 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    8000678c:	6605                	lui	a2,0x1
    8000678e:	4581                	li	a1,0
    80006790:	ffffa097          	auipc	ra,0xffffa
    80006794:	5a4080e7          	jalr	1444(ra) # 80000d34 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006798:	00026497          	auipc	s1,0x26
    8000679c:	1c848493          	addi	s1,s1,456 # 8002c960 <disk>
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
    800068d8:	1b450513          	addi	a0,a0,436 # 8002ca88 <disk+0x128>
    800068dc:	ffffa097          	auipc	ra,0xffffa
    800068e0:	35c080e7          	jalr	860(ra) # 80000c38 <acquire>
  for(int i = 0; i < 3; i++){
    800068e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800068e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800068e8:	00026b17          	auipc	s6,0x26
    800068ec:	078b0b13          	addi	s6,s6,120 # 8002c960 <disk>
  for(int i = 0; i < 3; i++){
    800068f0:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068f2:	00026c17          	auipc	s8,0x26
    800068f6:	196c0c13          	addi	s8,s8,406 # 8002ca88 <disk+0x128>
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
    80006918:	04c70713          	addi	a4,a4,76 # 8002c960 <disk>
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
    80006958:	02450513          	addi	a0,a0,36 # 8002c978 <disk+0x18>
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
    80006978:	fec78793          	addi	a5,a5,-20 # 8002c960 <disk>
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
    80006a4e:	03e90913          	addi	s2,s2,62 # 8002ca88 <disk+0x128>
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
    80006a7a:	eea78793          	addi	a5,a5,-278 # 8002c960 <disk>
    80006a7e:	97ba                	add	a5,a5,a4
    80006a80:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006a84:	00026997          	auipc	s3,0x26
    80006a88:	edc98993          	addi	s3,s3,-292 # 8002c960 <disk>
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
    80006ab0:	fdc50513          	addi	a0,a0,-36 # 8002ca88 <disk+0x128>
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
    80006ae4:	e8048493          	addi	s1,s1,-384 # 8002c960 <disk>
    80006ae8:	00026517          	auipc	a0,0x26
    80006aec:	fa050513          	addi	a0,a0,-96 # 8002ca88 <disk+0x128>
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
    80006b68:	f2450513          	addi	a0,a0,-220 # 8002ca88 <disk+0x128>
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
