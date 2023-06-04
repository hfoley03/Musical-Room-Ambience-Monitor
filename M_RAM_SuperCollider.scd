//Check the devices if wanted
s.options.sampleRate = 16000;
s.boot
s.sampleRate

// Set the connections for arduino and processing
(
~port = SerialPort.new("COM9",115200);
h = NetAddr("127.0.0.1",7771);
)

// Initialize everything
(
// Load the audio buffers for field recordings
~loadAudioIntoBuffers = {
	arg samples;
	~numframes = samples;
	d = Buffer.alloc(s, ~numframes);
	~rain = Buffer.read(s,Platform.resourceDir +/+ "sounds/rain_traffic.mp3",0,~numframes);
	~crickets = Buffer.read(s,Platform.resourceDir +/+ "sounds/crickets_light_rain.mp3",0,~numframes);
	~bird  = Buffer.read(s,Platform.resourceDir +/+ "sounds/bird-foley.wav",0,~numframes);
	~city  = Buffer.read(s,Platform.resourceDir +/+ "sounds/sunny_day.mp3",0,~numframes);
};

// call the above function for 5 seconds each file
~loadAudioIntoBuffers.value(44100*5);

// get the values from arduino using serial communication
~charArray = [ ];
~getValues = Routine.new(
	{ var ascii;
		{ascii = ~port.read.asAscii;
		if(ascii.isDecDigit,{~charArray = ~charArray.add(ascii)});
		if(ascii == $a,{
			~ambLight = ~charArray.collect(_.digit).convertDigits;
			~charArray = [ ]; });
		if(ascii == $b,{
			~infRed = ~charArray.collect(_.digit).convertDigits;
			~charArray = [ ]; });


}.loop;}
).play;

// Create the actual SynthDefs for each instrument
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

// the synth for white noise
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

        ]
    );

    filt = RLPF.ar(osc, cutoff, resonance);
	sig = filt * env * amp ;
	sig = Splay.ar(sig);

    // Output and panning
    Out.ar(out, sig);
}).add;

// synthdef of the field recordings
SynthDef(\fieldSamplePlayer, {
	|buffer_name, out, amp = 0.8|

	Out.ar([0,1],amp * PlayBuf.ar(1, buffer_name, BufRateScale.kr(d), doneAction: Done.freeSelf, loop: 1.0)) }).add;


// starts a new clock with 108 BPM and print the each beat
~startClock = {
	t = TempoClock.new(108/60);
	~postBeats = {t.beats.postln;1};
	t.schedAbs(t.nextBar, {~postBeats.value});
	t.beats; };


// Set the Presets using Pbindefs
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


// slow and repetetive
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

// the preset for night, using a noise and a pad
~presetNight = {
	t.tempo_(60/60);
	~noiseSynth.set(\amp,0.2,\cutoff,~ambLight.linlin(0,1023,200,3000));


	Pbindef(\p_pad,
		\type, \note,
		\instrument, \relaxingPad,
		\amp, 0.1,
		\midinote, Pshuf([50, 52, 54, 55],inf),
		\cutoff, ~ambLight,
		\dur, Pseq([8], inf)
	).play(t, quant:Quant.new(1,0,0));


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

~noiseSynth.set(\amp,0,\cutoff,~ambLight);


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
						{~stopMorDayEve.value; ~stopNig.value; ~fieldRecSynth.set(\amp, 0);},
						{
					switch (~synthMode,
								0, { ~stopNig.value; ~presetSlowRep.value; 'morning'.postln;
									~fieldRecSynth.set(\buffer_name, ~bird);
									if( (~ifFieldRec) == 0,
									{~fieldRecSynth.set(\amp, 0)},
									{~fieldRecSynth.set(\amp, 0.8)} );
								};,
								1, {~stopNig.value; 'day time'.postln;
									~fieldRecSynth.set(\buffer_name, ~city);
									if( (~ifFieldRec) == 0,
									{~fieldRecSynth.set(\amp, 0)},
									{~fieldRecSynth.set(\amp, 0.8)} );
									if ((~ambLight>700),{~presetFastDyn.value; },
										{~presetFastRep.value; };);
								}, // ambient sensor here, low -> repetitive, high -> dynamic},
								2, { ~stopNig.value;
									~presetSlowDyn.value;
									~fieldRecSynth.set(\buffer_name, ~city);
									if( (~ifFieldRec) == 0,
									{~fieldRecSynth.set(\amp, 0)},
									{~fieldRecSynth.set(\amp, 0.8)} );

								},
								3, { ~stopMorDayEve.value;
									~presetNight.value;
									~fieldRecSynth.set( \buffer_name, ~rain);
									if( (~ifFieldRec) == 0,
									{~fieldRecSynth.set(\amp, 0)},
									{~fieldRecSynth.set(\amp, 0.8)} );
 }
					);
						}
					);
					~update = 0;
					~update
				},
				// if no update from processing day time information
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

// the task calling the routine
~mainTask = Task({
    loop {
		~stopFlag = ~infRed; // will always be updated by ~infRed
		h.sendMsg("/cloudy", ~ambLight);
        ~main.reset;
		0.01.wait;
    }
});

// osc receiver to get messages from processing
~oscrec = OSCdef('OSCreceiver',
	{
		arg msg;

		~synthSelector = msg[1];
		~ifFieldRec = msg[2];
		~synthMode = msg[3]; // day mode

		},
	"/pos");

)

(
// Initializations of global variables and starting to play
// (
~wait_param = 0;                                       //secs
~synthMode = 0;                                        // need to change the update param with this
~infRed = 0;                                           // set the inital inffred to zero
~ambLight = 500;                                       // the initial ambLight value
~stopFlag = ~infRed;                                   // will always be updated by ~infRed
~update = 0;                                           // if we should update the playing sounds or not
~startClock.value;                                     // start the clock we are using
~synthSelector = 0;                                    // which synth is used
~noiseSynth = Synth(\whiteNoise, [\amp,0]);            // start the noise synth with 0 amplitude
~fieldRecSynth = Synth(\fieldSamplePlayer, [\amp,0]);  // start the noise synth with 0 amplitude
~main.play(t,quant:Quant.new(4,0,0) );                 // start the main routine after 4 beats
~mainTask.play;                                        // start the main task
)

~ifFieldRec = 1;
~startClock.value;

// update the mode
~wait_param = 0; //secs
~synthMode = 1;
~synthSelector = 0;
~update = 0;
~update.post
~infRed = 1;
~stopFlag = 1; //
~ambLight = 1000;

~presetFastRep.value

~oscrec.free

