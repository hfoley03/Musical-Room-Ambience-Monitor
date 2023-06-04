SerialPort.devices;

~ambLight // 0 is the dimmest
~infRed   // 1 if motion


~port = SerialPort.new("COM9",115200);

~charArray = [ ];
~getValues = Routine.new(
	{ var ascii;
		{ascii = ~port.read.asAscii;
		if(ascii.isDecDigit,{~charArray = ~charArray.add(ascii)});
		if(ascii == $a,{
			~ambLight = ~charArray.collect(_.digit).convertDigits;
			~charArray = [ ]; });
		if(ascii == $b,{
			~infRed = ~charArray.collect(_.digit).convertDigits.postln;
			~charArray = [ ]; });
			if (~val2 == 1

			) {~val2.postln};

}.loop;}
).play;

(




SynthDef(\smooth, { arg freq = 440, amp = 0.1, att = 0.1, rel = 2, lofreq = 1000, hifreq = 3000, pan = 1;
    var env, snd;
    env = Env.perc(
		attackTime: att,
		releaseTime: rel,
		level: amp
	).kr(doneAction: 2);
    snd = Saw.ar(freq: freq * [0.99, 1, 1.001, 1.008], mul: env);
	snd = LPF.ar(
		in: snd,
		freq: LFNoise2.kr(1).range(lofreq, hifreq)
	);
    snd = Splay.ar(snd);
	Out.ar(0, Pan2.ar(snd,pan));
}).add;


SynthDef(\lead, {
    arg freq = 440, attack = 0.1, release = 0.5, amp = 0.5, cutoff = 8000, resonance = 0.2;

    var env, sig, osc1, osc2, osc3;

    env = EnvGen.ar(Env.perc(attack, release), doneAction: 2);

    // First oscillator: Sawtooth wave
    osc1 = Saw.ar(freq);

    // Second oscillator: Square wave
    osc2 = Pulse.ar(freq * 1.01, 0.5);

    // Third oscillator: Triangle wave
    osc3 = LFTri.ar(freq * 0.99);

    sig = (osc1 + osc2 + osc3) * env;
    sig = LPF.ar(sig, cutoff, resonance)* amp;

    Out.ar(0, sig!2);
}).add;



SynthDef(\bass, { |out, freq = 440, gate = 1, amp = 0.8, slideTime = 0.17, ffreq = 1100, width = 0.15,
        detune = 1.005, preamp = 4|
    var sig, env;
    env = Env.adsr(0.01, 0.3, 0.4, 0.1);
    freq = Lag.kr(freq, slideTime);
    sig = Mix(VarSaw.ar([freq, freq * detune], 0, width, preamp)).distort * amp
        * EnvGen.kr(env, gate, doneAction: Done.freeSelf);
    sig = 2 * LPF.ar(sig, ffreq);
    Out.ar(out, sig ! 2)
}).add;

SynthDef(\hh, {
	arg freq = 600 ,amp = 0.15 , pan = 0, atk = 0.01,
	rel = 0.08, out = 0;
	var sig,env;
	env = 0.5 * EnvGen.kr(Env.perc(atk,rel),doneAction: 2);
	sig = WhiteNoise.ar(1) * env;
	sig = Pan2.ar(sig,pan,amp);
	Out.ar(0,sig);

}).add;

SynthDef(\whiteNoise, {
	arg amp = 0.5 , pan = 0, cutoff = 1000;	var sig;
	sig = WhiteNoise.ar(1);
	sig = RLPF.ar(sig, cutoff);
	sig = Pan2.ar(sig,pan)* amp;
	Out.ar(0,sig);

}).add;

SynthDef(\relaxingPad, {
    |out = 0, freq = 440, sustain = 4, attack = 3, release = 4, detune = 0.03, cutoff = 1000, resonance = 0.3, amp = 0.4, pan = 0|

    var env, osc, filt, sig;

    env = EnvGen.kr(Env.perc(attack, sustain, release), doneAction: 2);
    osc = Mix(
        [
            SinOsc.ar(freq + detune),
            SinOsc.ar(freq - detune).tanh,
			//WhiteNoise.ar(0.2);

        ]
    );

    filt = RLPF.ar(osc, cutoff, resonance);
	sig = filt * env * amp ;
	sig = Splay.ar(sig); //+ LPF.ar(WhiteNoise.ar(0.2),cutoff);

    // Output and panning
    Out.ar(out, sig);
}).add;



~startClock = {
t = TempoClock.new(108/60);//.permanent_(true); //makes the tempoclock permanent cntrl d doesnt kill t.
//t = TempoClock.new(60/60)
~postBeats = {t.beats.postln;1};
t.schedAbs(t.nextBar, {~postBeats.value});
	t.beats; };



// Fast and repetetive
~presetFastRep = {
	t.tempo_(108/60);
	if ( (~synthSelector == 0),{
	Pbindef(\p_smooth,
		\type, \note,
		\amp, 0.4,
		\instrument, \smooth,
		\midinote, Pseq([52,64,59,\],inf),
		\dur, Pseq([1/4], inf),
	).play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0
		).play(t, quant:Quant.new(4,0,0));
	}, {
	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0.4,
		\midinote, Pseq([52,64,59,\],inf),
		\dur, Pseq([1/4], inf),
		).play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_smooth,
		\amp, 0,
		\instrument, \smooth
	).play(t, quant:Quant.new(4,0,0));

	});


	Pbindef(\p_bass,
		\instrument, \bass,
		\amp, 0.5,
		\midinote, Pshuf([
			52,64,59,\,
			40,37,38,\
		],inf) + [ -3,-5,-7, -9, -12 ,-3, 0, 5,7,9,12 ].choose,
		\dur, Pseq([1/4], inf)
	).play(t, quant:Quant.new(4,0,0));


	Pbindef(\p_hh,
		\type, \note,
		\instrument, \hh,
		\amp, Pshuf((~ambLight.linlin(0,1023,0.05,1.5) * [0.1,0.7,0.7,0.1]).stutter(16),inf),
		\dur, Pseq([1/4], inf),
		\rel, Pseq([0.03], inf)
	).play(t, quant:Quant.new(4,0,0));

};





// Fast and dynamic

~presetFastDyn = {
	var transpose;
	t.tempo_(108/60);

	transpose = [-7,-5,0].choose;

	if ( (~synthSelector == 0),
		{
	Pbindef(\p_smooth,
		\instrument, \smooth,
		\amp, 0.4,
		\dur, Prand([1/4],inf),
		\midinote, Pshuf([60,62,64,67,69,72,74,\,\,\,\].stutter(4) + transpose, inf))
	.play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0
		).play(t, quant:Quant.new(4,0,0));
	},
	{
	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0.4,
		\dur, Prand([1/4],inf),
		\midinote, Pshuf([60,62,64,67,69,72,74,\,\,\,\].stutter(4) + transpose, inf))
	.play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_smooth,
		\amp, 0,
		\instrument, \smooth
	).play(t, quant:Quant.new(4,0,0));
	});
	Pbindef(\p_bass,
		\instrument, \bass,
		\amp, 0.5,
		\dur, Prand([1/4],inf),
		\midinote, Pshuf([60,62,64,67,69,72,74,\,\,\,\].stutter(4) + transpose - 12, inf))
	.play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_hh,
		\type, \note,
		\instrument, \hh,
		\amp, Pshuf((~ambLight.linlin(0,1023,0.05,1.5) * [0.1,0.7,0.7,0.1]).stutter(16),inf),
		\dur, Pseq([1/4], inf),
		\rel, Pseq([0.03], inf)
	).play(t, quant:Quant.new(4,0,0));
};



// slow and dynamic

~presetSlowDyn = {
	var transpose;
	t.tempo_(60/60);
	transpose = [-7,-5,0].choose;

	if ( (~synthSelector == 0),
		{
	Pbindef(\p_smooth,
		\instrument, \smooth,
		\amp, 0.4,
		\dur, Prand([1/4],inf),
		\midinote, Pshuf([60,62,64,67,69,72,74,\,\,\,\].stutter(4) + transpose, inf))
	.play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0
		).play(t, quant:Quant.new(4,0,0));
	},
	{
	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0.4,
		\dur, Prand([1/4],inf),
		\midinote, Pshuf([60,62,64,67,69,72,74,\,\,\,\].stutter(4) + transpose, inf))
	.play(t, quant:Quant.new(4,0,0));


	Pbindef(\p_smooth,
		\amp, 0,
		\instrument, \smooth
	).play(t, quant:Quant.new(4,0,0));

	});
	Pbindef(\p_bass,
		\instrument, \bass,
		\amp, 0.5,
		\dur, Prand([1/4],inf),
		\midinote, Pshuf([60,62,64,67,69,72,74,\,\,\,\].stutter(4) + transpose - 12, inf))
	.play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_hh,
		\type, \note,
		\instrument, \hh,
		\amp, Pshuf((~ambLight.linlin(0,1023,0.05,1.5) * [0.1,0.7,0.7,0.1]).stutter(16),inf),
		\dur, Pseq([1/4], inf),
		\rel, Pseq([0.03], inf)
	).play(t, quant:Quant.new(4,0,0));
};



~presetSlowRep = {
	t.tempo_(60/60);

	if ( (~synthSelector == 0),{
	Pbindef(\p_smooth,
		\type, \note,
		\amp, 0.4,
		\instrument, \smooth,
		\midinote, Pseq([52,64,59,\],inf),
		\dur, Pseq([1/4], inf),
	).play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0
		).play(t, quant:Quant.new(4,0,0));
	}, {
	Pbindef(\p_lead,
		\instrument, \lead,
		\amp, 0.4,
		\midinote, Pseq([52,64,59,\],inf),
		\dur, Pseq([1/4], inf),
		).play(t, quant:Quant.new(4,0,0));

	Pbindef(\p_smooth,
		\amp, 0,
		\instrument, \smooth
	).play(t, quant:Quant.new(4,0,0));

	});


	Pbindef(\p_bass,
		\instrument, \bass,
		\amp, 0.5,
		\midinote, Pshuf([
			52,64,59,\,
			40,37,38,\
		],inf) + [ -3,-5,-7, -9, -12 ,-3, 0, 5,7,9,12 ].choose,
		\dur, Pseq([1/4], inf)
	).play(t, quant:Quant.new(4,0,0));


	Pbindef(\p_hh,
		\type, \note,
		\instrument, \hh,
		\amp, Pshuf((~ambLight.linlin(0,1023,0.05,1.5) * [0.1,0.7,0.7,0.1]).stutter(16),inf),
		\dur, Pseq([1/4], inf),
		\rel, Pseq([0.03], inf)
	).play(t, quant:Quant.new(4,0,0));



};

~presetNight = {
	t.tempo_(60/60);
	x.set(\amp,0.3,\cutoff,~ambLight.linlin(0,1023,200,8000));


Pbindef(\p_pad,
	\type, \note,
	\instrument, \relaxingPad,
	\amp, 0.1,
	\midinote, Pshuf([50, 52, 54, 55],inf),
	\cutoff, ~ambLight,
	\dur, Pseq([8], inf)
).play(t, quant:Quant.new(4,0,0));


};


~stopMorDayEve ={


Pbindef(\p_smooth,
	\amp, 0
).play(t, quant:Quant.new(4,0,0));


Pbindef(\p_bass,
	\amp, 0
).play(t, quant:Quant.new(4,0,0));

Pbindef(\p_lead,
	\amp, 0
).play(t, quant:Quant.new(4,0,0));


Pbindef(\p_hh,
	\amp, 0
).play(t, quant:Quant.new(4,0,0));
};

~stopNig ={

x.set(\amp,0,\cutoff,~ambLight);


Pbindef(\p_pad,
	\amp, 0
).play(t, quant:Quant.new(4,0,0));
};

~main = Routine.new(
	{

		{
			0.01.wait; //repeat the routine every .1 secs
			// if synths should change
			if(   ~update == 1,
				{
					if ( (~stopFlag != 1),
						{~stopMorDayEve.value; ~stopNig.value;},
						{
					switch (~synthMode,
						0, { ~stopNig.value; ~presetSlowRep.value; 'morning'.postln},
						1, {
							~stopNig.value; 'day time'.postln;
							if ((~ambLight>700),{~presetFastDyn.value; },  {~presetFastRep.value; };);
								}, // ambient sensor here, low -> repetitive, high -> dynamic},
						2, { ~stopNig.value; ~presetSlowDyn.value; },
						3, { ~stopMorDayEve.value;~presetNight.value }
					);
						}
					);
					~update = 0;
					~update.postln
				},
				// dont update
				{
					~wait_param = ~wait_param + 0.1;
					//~wait_param.postln;
					// if update param is 0 for too long, make it 1.
					if(~wait_param > 5){
						~wait_param = 0;
						~update = 1;
					};
				}
				;
			)
	}.loop;}
);

~mainTask = Task({
    loop {
		~stopFlag = ~infRed;
        ~main.reset;
		0.01.wait;
		//'waited 1'.postln;

    }
});


~oscrec = OSCdef('OSCreceiver',
	{
		arg msg;
		//var melodySelector;
		//x = msg[1];
		//y = msg[2];
		~synthSelector = msg[3];
		~synthMode = msg[4];
		// x corresponds to panning, so it has to be between -1 and 1 (now is between 0 and 1)
		//x = (x-0.5)/0.5;
		//y = y/2;

		//postln(~synthMode);

		//if(melodySelector ==1){"mel1".postln}

	},
	"/pos");



)


(
// update the mode
~wait_param = 0; //secs
~synthMode = 3; // need to change the update param with this
~infRed = 0; // comment th
~stopFlag = ~infRed; // will updated by ~infRed, maybe directly use ~infRed
~update = 0;
~ambLight = 1000; // comment this as well
~startClock.value;
~synthSelector = 0;
//~presetFastRep.value;
x = Synth(\whiteNoise, [\amp,0]);
~main.play(t,quant:Quant.new(4,0,0) );
~mainTask.play;
)

~startClock.value;

// update the mode
~wait_param = 0; //secs
~synthMode = 1;
~synthSelector = 1;
~update = 0;
~update.post
~infRed = 1;
~stopFlag = 1; //
~ambLight = 5000;

~presetFastRep.value