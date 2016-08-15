(* Automatic *)
Needs["SubKernels`RemoteKernels`"];
Get["tunnel.m"];
kernels = RemoteMachineTunnel["ahassel@ttp7of9.ttp.kit.edu", 2, "OperatingSystem" -> "Unix", "KernelPath" -> "/export/pc/bin/math"];
kls = LaunchKernels[kernels];
ParallelEvaluate[$MachineName];
CloseKernels[kls];

(* Manual *)
Needs["SubKernels`RemoteKernels`"];
$RemoteCommand = "\"" <> $UserBaseDirectory <> "/FrontEnd/tunnel_qsub.sh\" \"`1`\" /export/pc/bin/math \"`2`\"";
Parallel`Settings`$MathLinkTimeout = 31536000;
kernel = RemoteMachine["GridEngine", LinkHost -> "127.0.0.1"];
ks = LaunchKernels[kernel];
mn = ParallelEvaluate[$MachineName];
Print[mn];
Print[CloseKernels[ks]];

<<"/x2/ahassel/Tunnel/scripts/QsubParallelDo.m";
$QsubArguments="-q *@t*"
