defmodule RunletCtrlHelpTest do
  use ExUnit.Case

  test "help command" do
    commands = [
      {"cmd", {[:Runlet, :Cmd, :Query], :exec}},
      {"ctrl", {[:Runlet, :Ctrl, :Help], :exec}},
      {"multicmd",
       [
         {[:Runlet, :Cmd, :Query], :exec},
         {{[:Runlet, :Cmd, :Valve], :exec}, []},
         {{[:Runlet, :Cmd, :Flow], :exec}, [20, 100]}
       ]},
      {"multictrl",
       [
         {[:Runlet, :Ctrl, :Ps], :exec},
         {{[:Runlet, :Cmd, :Valve], :exec}, []},
         {{[:Runlet, :Cmd, :Flow], :exec}, [20, 100]}
       ]},
      {"cmdopt",
       [
         {{[:Runlet, :Cmd, :Query], :exec}, [~s(service = "billing_event")]}
       ]},
      {"ctrlopt",
       [
         {{[:Runlet, :Ctrl, :Help], :exec}, [~s(help)]}
       ]},
      {"defopt", {[:Runlet, :Cmd, :Threshold], :exec}}
    ]

    env = %Runlet{aliases: commands}

    assert [
             %Runlet.Event{event: %Runlet.Event.Ctrl{description: description}}
             | _
           ] = Runlet.Ctrl.Help.exec(env)

    assert true = is_binary(description)

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: cmd: <q>\n\n", _::binary>>
               }
             }
             | _
           ] = Runlet.Ctrl.Help.exec(env, "cmd")

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: ctrl: \n\n", _::binary>>
               }
             }
             | _
           ] = Runlet.Ctrl.Help.exec(env, "ctrl")

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: multicmd: <q>\n\n", _::binary>>
               }
             }
             | _
           ] = Runlet.Ctrl.Help.exec(env, "multicmd")

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: multictrl: \n\n", _::binary>>
               }
             },
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: multictrl: <uid>\n\n", _::binary>>
               }
             }
           ] = Runlet.Ctrl.Help.exec(env, "multictrl")

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: cmdopt: <q>\n\n", _::binary>>
               }
             }
           ] = Runlet.Ctrl.Help.exec(env, "cmdopt")

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: ctrlopt: \n\n", _::binary>>
               }
             },
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"usage: ctrlopt: <cmd>\n\n", _::binary>>
               }
             }
           ] = Runlet.Ctrl.Help.exec(env, "ctrlopt")

    assert [
      [
        %Runlet.Event{
          event: %Runlet.Event.Ctrl{
            description:
              <<"usage: defopt: <count> <seconds \\\\ 60>", _::binary>>
          }
        }
      ] = Runlet.Ctrl.Help.exec(env, "defopt")
    ]
  end
end
