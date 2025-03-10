s.waitForBoot
{

var x = { | gain=0.9, delay=0.5| var input = SoundIn.ar(0);

        var processed = DelayC.ar(input, 2, delay, gain);
        Out.ar(0, processed);
}.play;

var w = Window("Slider", Rect(128, 64, 1200, 800));

var button = Button(w, Rect(400,50,100,100));

var freqSlider = Slider(w, Rect(100,300,600,50));
var rangeSlider = Slider(w, Rect(100,400,600,50));
var durSlider = Slider(w, Rect(100,500,600,50));

var freqText = TextField(w, Rect(10, 300, 50, 50));
var rangeText = TextField(w, Rect(10, 400, 50, 50));
var durText = TextField(w, Rect(10, 500, 50, 50));
var buttonText = TextField(w, Rect(250, 50, 100, 100));
freqText.string = "Start Pitch";
rangeText.string = "Wave Range";
durText.string = "Wave Duration";
buttonText.string = "Play a Wave";

SynthDef(\Wave, {
	|out = 0.5, freq = 400, range = 200, dur = 2.1|

	var ampEnv = EnvGen.kr(Env([0, 1, 0], [dur/2, dur/2]), doneAction: Done.freeSelf);
	var freqEnv = EnvGen.kr(Env([freq, freq+range, freq], [dur/2, dur/2], \sin), doneAction: Done.freeSelf);
    Out.ar(0,
		LPF.ar(in: WhiteNoise.ar(out), freq: freqEnv) * ampEnv
    );
}).send(s);

freqSlider.action_({~wave_synth.set(\freq,
	linlin(freqSlider.value.postln, 0, 1, 400, 2000))
});
rangeSlider.action_({~wave_synth.set(\range,
	linlin(rangeSlider.value.postln, 0, 1, 200, 600))
});
durSlider.action_({~wave_synth.set(\dur,
	linlin(durSlider.value.postln, 0, 1, 2.1, 6.1))
});

button.mouseDownAction = {~wave_synth = Synth(\Wave,
	[\out, 0.5, \freq, linlin(freqSlider.value.postln, 0, 1, 400, 2000),
	 \dur, linlin(durSlider.value.postln, 0, 1, 2.1, 6.1),
	 \range, linlin(rangeSlider.value.postln, 0, 1, 200, 600)]
)};

//w.fullScreen;
w.front;
};