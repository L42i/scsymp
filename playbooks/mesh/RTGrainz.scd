// Granular synth definition
 
// 5 second Buffer
 
s.options.numOutputBusChannels = 12;
s.options.numInputBusChannels = 2;
 
 
(
s.waitForBoot({
 
b = Buffer.alloc(s, s.sampleRate * 5, 1);
 
s.sync;
 
// mic for recording and pointer to point which sample to record from
 
 
~micBus = Bus.audio(s,1);
~ptrBus = Bus.audio(s,1);
 
s.sync;
 
// read a signal from a hardware input bus, with an amplitude control jto mute or adjust the level
 
 
 
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in) * amp;
	Out.ar(out, sig);
}).add;
 
s.sync;
 
// The ringBuffer phasor, with the buff and output as an argument to write from
SynthDef.new(\ptr, {
	arg out=0, buf=0, rate=1;
	var sig;
	sig = Phasor.ar(0, BufRateScale.kr(buf)*rate, 0, BufFrames.kr(buf));
	// sig.poll;
	Out.ar(out, sig);
}).add;
 
s.sync;
 
Synth(\ptr, [\buf, b, \out, ~ptrBus], ~ptrGrp);
~ptrGrp.set(\rate,1);
 
s.sync;
 
// Writing into the buffer with our pointer
 
SynthDef.new(\rec, {
	arg ptrIn=0, micIn=0, buf=0;
	var ptr, sig;
	ptr = In.ar(ptrIn, 1);
	sig = In.ar(micIn, 1);
	BufWr.ar(sig, buf, ptr);
}).add;
 
s.sync;
 
SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0, grainEnv=(-1),
	ptrBus=0, ptrSampleDelay=20000,
	ptrRandSamples=5000, minPtrDelay=1000;
 
	var sig, env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr, ptrRand, totalDelay, maxGrainDur;
 
	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);
 
	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);
 
	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.ir(buf);
 
	maxGrainDur = (totalDelay / rateCtrl) / SampleRate.ir;
	durCtrl = min(durCtrl, maxGrainDur);
 
	sig = GrainBuf.ar(
		2,
		densCtrl,
		durCtrl,
		buf,
		rateCtrl,
		ptr,
		2,
		panCtrl,
		grainEnv
	);
 
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;
 
s.sync;
 
 
~micGrp = Group.new;
s.sync;
~ptrGrp = Group.after(~micGrp);
s.sync;
~recGrp = Group.after(~ptrGrp);
s.sync;
~granGrp = Group.after(~recGrp);
s.sync;
 
 
Synth(\mic, [\in, 0, \out, ~micBus], ~micGrp);
Synth(\ptr, [\buf, b, \out, ~ptrBus], ~ptrGrp);
Synth(\rec, [\ptrIn, ~ptrBus, \micIn, ~micBus, \buf, b], ~recGrp);
s.sync;
 
 
// Adding about 5 grain read pointers behind the write pointer
 
b.zero;
 
~g = 12.collect({
	arg n; // is the argument of pointers
	Synth(\gran,
		[
			\amp, n.linlin(0,11,-3,-20).dbamp, // linearly mapping the amplitude based on read pointer position
			\buf, b,
			\out, n,
			\atk, 1,
			\rel, 4,
			\gate, 1,
			\sync, 1, // Synchronous or asynchronous
			\dens, exprand(20,40), // how many grains a second
			\baseDur, 0.08, // Duration of each grain
			\durRand, 1,
			\rate, 1,
			\rateRand, 1,  // changes the playback rate randomness so t
			\pan, 0,
			\panRand, 0.5,
			\grainEnv, -1,
			\ptrBus, ~ptrBus,
			\ptrSampleDelay, n.linlin(0,11,20000,s.sampleRate * 3),
			\ptrRandSamples, 10000, //Grain pointer smoothly or randomly following record pointer
			\minPtrDelay, 1000;
		],
		~granGrp
	);
});
 
~forwarder = {Out.ar(0,0.08*SoundIn.ar(Array.fill(12,{1})))}.play;
 
s.meter;
 
// Slider to control playback rate
 
w = Window("GUI", Rect(500, 500, 400, 300)).front.alwaysOnTop_(true)
	.background_(Color.new255(220, 245, 255));
 
// Slider 1: Pointer Motion
StaticText(w, Rect(50, 30, 150, 20))
	.string_("Pointer Randomness")
.align_(\center)
.background_(Color.new255(240, 240, 240));
 
~slider1 = Slider(w, Rect(50, 50, 150, 20))
	.background_(Color.blue(0.3, 0.2))
.action_({
	arg sliderVal;
	// Example action for slider 1
	var expVal = sliderVal.value.linexp(0, 1, 600, s.sampleRate/3).postln;
	~g.do({ arg n; n.set(\ptrRandSamples, expVal) });
});
 
// Slider 2: Density
StaticText(w, Rect(50, 100, 150, 20))
	.string_("Density")
	.align_(\center)
	.background_(Color.new255(240, 240, 240));
 
~slider2 = Slider(w, Rect(50, 120, 150, 20))
	.background_(Color.blue(0.3, 0.2))
	.action_({
		arg sliderVal;
		// Linear mapping for amplitude (0 to 1)
		var denseVal = sliderVal.value.linexp(0, 1, 5, 120).postln;
		~g.do({ arg n; n.set(\dens, denseVal) });
	});
 
	~btn = Button.new(w, Rect(210, 100, 50,30))
	.states_([
		["Async", Color.white,  Color.new255(200, 50, 50)],
		["Sync", Color.black, Color.new255(50, 200, 100)]
	])
	.action_({
		arg btnstate;
		~g.do({ arg n; n.set(\sync, btnstate.value) });
 
	});
 
// Slider 3: Grain Playback Rate
StaticText(w, Rect(50, 170, 150, 20))
	.string_("Playback Rate")
	.align_(\center)
	.background_(Color.new255(240, 240, 240));
 
~slider3 = Slider(w, Rect(50, 190, 150, 20))
	.background_(Color.blue(0.3, 0.2))
	.action_({
		arg sliderVal;
		// Linear mapping for amplitude (0 to 1)
		var rateVal = sliderVal.value.linlin(0, 1, -5.midiratio, 3.midiratio).postln;
		~g.do({ arg n; n.set(\rate, rateVal) });
	});
 
// Slider 4: Grain Size
StaticText(w, Rect(225, 30, 150, 20))
	.string_("Grain Size")
	.align_(\center)
	.background_(Color.new255(240, 240, 240));
 
~slider4 = Slider(w, Rect(290, 50, 20, 150))
	.background_(Color.blue(0.3, 0.2))
	.action_({
		arg sliderVal;
		var sizeVal = sliderVal.value.linexp(0, 1, 0.01, 0.1).postln;
		~g.do({ arg n; n.set(\baseDur, sizeVal) });
	});
 
//Knob for Duration Randomization
	~knb = Knob.new(w, Rect(50, 220, 50,50))
	.action_({
		arg knobVal;
		var durRandVal = knobVal.value.linexp(0,1,1,10.midiratio).postln;
		~g.do({ arg n; n.set(\rateRand, durRandVal) });
	});
	StaticText(w, Rect(50, 280, 50, 50))
	.string_("Rate Rand")
	.align_(\center)
	.background_(Color.new255(240, 240, 240));
 
 
});
)