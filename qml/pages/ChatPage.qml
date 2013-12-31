/*
  Copyright (C) 2013-2014 Robin Burchell <robin+git@viroteck.net>
  Copyright (C) 2013-2014 J-P Nurmi <jpnurmi@gmail.com>

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.1
import Communi 3.1
import Sailfish.Silica 1.0

Page {
    id: page

    property IrcBuffer buffer

    Binding {
        target: MessageStorage.get(buffer)
        property: "active"
        value: page.status === PageStatus.Active
    }

    SilicaListView {
        id: view
        clip: true
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: field.top }

        header: PageHeader { title: buffer.title }

        model: MessageStorage.get(buffer)

        delegate: Label {
            text: display
            anchors { left: parent.left; right: parent.right; margins: Theme.paddingLarge }
            wrapMode: Text.Wrap
            linkColor: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            onLinkActivated: Qt.openUrlExternally(link)
            color: highlight ? "#ff4d4d" : seen ? Theme.secondaryColor : Theme.primaryColor
        }

        onCountChanged: {
            if (view.visibleArea.yPosition + view.visibleArea.heightRatio > 0.9)
                positioner.start()
        }
        Component.onCompleted: view.positionViewAtEnd()
    }

    Timer {
        id: positioner
        interval: 100
        onTriggered: if (!view.moving) view.positionViewAtEnd()
    }

    IrcCommandParser {
        id: parser

        tolerant: true
        triggers: ["/"]
        channels: buffer.model.channels
        target: buffer.title

        Component.onCompleted: {
            parser.addCommand(IrcCommand.CtcpAction, "ACTION <target> <message...>")
            parser.addCommand(IrcCommand.Admin, "ADMIN (<server>)")
            parser.addCommand(IrcCommand.Away, "AWAY (<reason...>)")
            parser.addCommand(IrcCommand.Info, "INFO (<server>)")
            parser.addCommand(IrcCommand.Invite, "INVITE <user> (<#channel>)")
            parser.addCommand(IrcCommand.Join, "JOIN <#channel> (<key>)")
            parser.addCommand(IrcCommand.Kick, "KICK (<#channel>) <user> (<reason...>)")
            parser.addCommand(IrcCommand.Knock, "KNOCK <#channel> (<message...>)")
            parser.addCommand(IrcCommand.List, "LIST (<channels>) (<server>)")
            parser.addCommand(IrcCommand.CtcpAction, "ME [target] <message...>")
            parser.addCommand(IrcCommand.Mode, "MODE (<channel/user>) (<mode>) (<arg>)")
            parser.addCommand(IrcCommand.Motd, "MOTD (<server>)")
            parser.addCommand(IrcCommand.Names, "NAMES (<#channel>)")
            parser.addCommand(IrcCommand.Nick, "NICK <nick>")
            parser.addCommand(IrcCommand.Notice, "NOTICE <#channel/user> <message...>")
            parser.addCommand(IrcCommand.Part, "PART (<#channel>) (<message...>)")
            parser.addCommand(IrcCommand.Ping, "PING (<user>)")
            parser.addCommand(IrcCommand.Quit, "QUIT (<message...>)")
            parser.addCommand(IrcCommand.Quote, "QUOTE <command> (<parameters...>)")
            parser.addCommand(IrcCommand.Stats, "STATS <query> (<server>)")
            parser.addCommand(IrcCommand.Time, "TIME (<user>)")
            parser.addCommand(IrcCommand.Topic, "TOPIC (<#channel>) (<topic...>)")
            parser.addCommand(IrcCommand.Trace, "TRACE (<target>)")
            parser.addCommand(IrcCommand.Users, "USERS (<server>)")
            parser.addCommand(IrcCommand.Version, "VERSION (<user>)")
            parser.addCommand(IrcCommand.Who, "WHO <mask>")
            parser.addCommand(IrcCommand.Whois, "WHOIS <user>")
            parser.addCommand(IrcCommand.Whowas, "WHOWAS <user>")

            // TODO: "custom" commands
            //parser.addCommand(IrcCommand.Custom, "CLEAR")
            //parser.addCommand(IrcCommand.Custom, "CLOSE")
            //parser.addCommand(IrcCommand.Custom, "QUERY <user> (<message...>)")
            //parser.addCommand(IrcCommand.Custom, "MSG <user/channel> <message...>")
        }
    }

    TextField {
        id: field
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }

        EnterKey.text: qsTr("Send")
        EnterKey.enabled: !!text
        EnterKey.highlighted: true

        placeholderText: qsTr("Hi, %1").arg(buffer.title)
        placeholderColor: Theme.secondaryHighlightColor

        Keys.onReturnPressed: {
            var cmd = parser.parse(text)
            if (cmd) {
                buffer.connection.sendCommand(cmd)
                if (cmd.type === IrcCommand.Message
                        || cmd.type === IrcCommand.CtcpAction
                        || cmd.type === IrcCommand.Notice) {
                    var msg = cmd.toMessage(buffer.connection.nickName, buffer.connection)
                    buffer.receiveMessage(msg)
                }
                field.text = ""
            }
        }
    }
}