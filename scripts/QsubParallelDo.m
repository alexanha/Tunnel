BeginPackage["QsubParallelDo`",{"SubKernels`RemoteKernels`","Parallel`Developer`"}]

QsubKernel::usage = "QsubTunnel[] launches a Mathematica SubKernel via qsub. Takes one Option Timeout, which defaults to 15 seconds. Infinity is a shorthand for one year.";
QsubParallelDo::usage = "QsubParallelDo[expr, {i,imin,imax}]: ";
$QsubLogDir::usage = "Full path to Log directory. If empty, the $UserBaseDirectory/FrontEnd/Logs is used.";
$QsubArguments::usage = "String containing the qsub arguments.";

$QsubLogDir="";
$QsubArguments="";

Begin["`Private`"]

Options[QsubKernel] := {Timeout->15};
QsubKernel[OptionsPattern[]] := Module[{timeout=OptionValue[Timeout],kernel,kid,logdir=$QsubLogDir},
  If[timeout===Infinity, timeout = 365*24*3600];
  Print[timeout];
  If[logdir==="", logdir=$UserBaseDirectory<>"/FrontEnd/Logs"];
  SubKernels`RemoteKernels`$RemoteCommand = "\"" <> System`$UserBaseDirectory <> "/FrontEnd/tunnel_qsub.sh\" /export/pc/bin/math \"`2`\" \""<>logdir<>"\" \""<>$QsubArguments<>"\"";
  Parallel`Settings`$MathLinkTimeout = timeout;
  kernel = SubKernels`RemoteKernels`RemoteMachine["GridEngine", System`LinkHost -> "127.0.0.1"];
  kid = System`LaunchKernels[kernel];
kid];

SetAttributes[QsubParallelDo,HoldFirst];
Options[QsubParallelDo] = {MaxNumberOfKernels->10};
QsubParallelDo[expr_, {i_,imax_}, opt:OptionsPattern[]] := QsubParallelDo[expr, {i,1,imax},opt];
QsubParallelDo[expr_, {i_,imin_,imax_}, opt:OptionsPattern[]] := Module[{nkernels=OptionValue[MaxNumberOfKernels],num,kidlist={},kid,myexpr,dummy,myBlock,j,k,l,dellist={},tmpkid,tmpres,tmpnr,run1,mySend,SendCommand,GetResults},
  GetResults[] := Module[{$Done},
      kidlist = Map[Module[{tmpres},
        tmpres = Parallel`Developer`ReceiveIfReady[#[[2]]];
        If[tmpres===Parallel`Developer`$NotReady,
          #,
        (*else*)
          results[[#[[1]]]] = tmpres;
          CloseKernels[#[[2]]];
          $Done
        ]]&,kidlist];
      kidlist = Select[kidlist,#=!=$Done&];
  kidlist];
  SetAttributes[mySend,HoldRest];
  offset = imin-1;
  num = imax-offset;
  results = Table[dummy,{j,1,num}];
  Do[
(* queue a new process *)
    kid = QsubKernel[Timeout->Infinity];
    AppendTo[kidlist,{j,kid}];
    SendCommand = mySend[kid, Block[{i=k}, dummy]]/.dummy:>Unevaluated[expr]/.k->j+offset;
    SendCommand = SendCommand/.mySend->Parallel`Developer`Send;
 (* check for new results *)
    run1=True;
    While[run1||Length[kidlist]>=nkernels,
      run1 = False;
      GetResults[];
    ];
  ,{j,1,num}];
  While[Length[kidlist]>0,
    GetResults[];
  ];
results];

End[]

EndPackage[]
