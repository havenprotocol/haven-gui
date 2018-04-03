// Copyright (c) 2014-2015, The Monero Project
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are
// permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of
//    conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice, this list
//    of conditions and the following disclaimer in the documentation and/or other
//    materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors may be
//    used to endorse or promote products derived from this software without specific
//    prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
// THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import "../components"
import moneroComponents.Clipboard 1.0
import moneroComponents.Wallet 1.0
import moneroComponents.WalletManager 1.0
import moneroComponents.TransactionHistory 1.0
import moneroComponents.TransactionHistoryModel 1.0
import moneroComponents.Subaddress 1.0
import moneroComponents.SubaddressModel 1.0

Rectangle {
    id: pageReceive
    color: "#F0EEEE"
    property var model
    property var current_address
    property alias addressText : pageReceive.current_address

    function makeQRCodeString() {
        var s = "monero:"
        var nfields = 0
        s += current_address;
        var amount = amountLine.text.trim()
        if (amount !== "") {
          s += (nfields++ ? "&" : "?")
          s += "tx_amount=" + amount
        }
        return s
    }

    Clipboard { id: clipboard }


    /* main layout */
    ColumnLayout {
        id: mainLayout
        anchors.margins: (isMobile)? 17 : 40
        anchors.topMargin: 40 * scaleRatio

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right

        spacing: 20 * scaleRatio
        property int labelWidth: 120 * scaleRatio
        property int editWidth: 400 * scaleRatio
        property int lineEditFontSize: 12 * scaleRatio
        property int qrCodeSize: 240 * scaleRatio


        ColumnLayout {
            id: addressRow
            Label {
                id: addressLabel
                text: qsTr("Addresses") + translationManager.emptyString
                width: mainLayout.labelWidth
            }

            Rectangle {
                id: tableRect
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: "#FFFFFF"
                Scroll {
                    id: flickableScroll
                    anchors.right: table.right
                    anchors.top: table.top
                    anchors.bottom: table.bottom
                    flickable: table
                }
                SubaddressTable {
                    id: table
                    anchors.fill: parent
                    onContentYChanged: flickableScroll.flickableContentYChanged()
                    onCurrentItemChanged: {
                        current_address = appWindow.currentWallet.address(appWindow.currentWallet.currentSubaddressAccount, table.currentIndex);
                    }
                }
            }
            RowLayout {
                spacing: 20
                StandardButton {
                    shadowReleasedColor: "#0c091d"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#142f38"
                    pressedColor: "#0c091d"
                    text: qsTr("Create new address") + translationManager.emptyString;
                    onClicked: {
                        inputDialog.labelText = qsTr("Set the label of the new address:") + translationManager.emptyString
                        inputDialog.inputText = qsTr("(Untitled)")
                        inputDialog.onAcceptedCallback = function() {
                            appWindow.currentWallet.subaddress.addRow(appWindow.currentWallet.currentSubaddressAccount, inputDialog.inputText)
                            table.currentIndex = appWindow.currentWallet.numSubaddresses() - 1
                        }
                        inputDialog.onRejectedCallback = null;
                        inputDialog.open()
                    }
                }
                StandardButton {
                    shadowReleasedColor: "#0c091d"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#142f38"
                    pressedColor: "#0c091d"
                    enabled: table.currentIndex > 0
                    text: qsTr("Rename") + translationManager.emptyString;
                    onClicked: {
                        inputDialog.labelText = qsTr("Set the label of the selected address:") + translationManager.emptyString
                        inputDialog.inputText = appWindow.currentWallet.getSubaddressLabel(appWindow.currentWallet.currentSubaddressAccount, table.currentIndex)
                        inputDialog.onAcceptedCallback = function() {
                            appWindow.currentWallet.subaddress.setLabel(appWindow.currentWallet.currentSubaddressAccount, table.currentIndex, inputDialog.inputText)
                        }
                        inputDialog.onRejectedCallback = null;
                        inputDialog.open()
                    }
                }
            }
        }


        ColumnLayout {
            id: amountRow
            Label {
                id: amountLabel
                text: qsTr("Amount") + translationManager.emptyString
                width: mainLayout.labelWidth
            }


            LineEdit {
                id: amountLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("Amount to receive") + translationManager.emptyString
                readOnly: false
                width: mainLayout.editWidth
                Layout.fillWidth: true
                validator: DoubleValidator {
                    bottom: 0.0
                    top: 18446744.073709551615
                    decimals: 12
                    notation: DoubleValidator.StandardNotation
                    locale: "C"
                }
            }
        }

        FileDialog {
            id: qrFileDialog
            title: "Please choose a name"
            folder: shortcuts.pictures
            selectExisting: false
            nameFilters: [ "Image (*.png)"]
            onAccepted: {
                if( ! walletManager.saveQrCode(makeQRCodeString(), walletManager.urlToLocalPath(fileUrl))) {
                    console.log("Failed to save QrCode to file " + walletManager.urlToLocalPath(fileUrl) )
                    trackingHowToUseDialog.title  = qsTr("Save QrCode") + translationManager.emptyString;
                    trackingHowToUseDialog.text = qsTr("Failed to save QrCode to ") + walletManager.urlToLocalPath(fileUrl) + translationManager.emptyString;
                    trackingHowToUseDialog.icon = StandardIcon.Error
                    trackingHowToUseDialog.open()
                }
            }
        }
        ColumnLayout {
            Menu {
                id: qrMenu
                title: "QrCode"
                MenuItem {
                   text: qsTr("Save As") + translationManager.emptyString;
                   onTriggered: qrFileDialog.open()
                }
            }

            Image {
                id: qrCode
                anchors.margins: 50 * scaleRatio
                Layout.fillWidth: true
                Layout.minimumHeight: mainLayout.qrCodeSize
                smooth: false
                fillMode: Image.PreserveAspectFit
                source: "image://qrcode/" + makeQRCodeString()
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (mouse.button == Qt.RightButton)
                            qrMenu.popup()
                    }
                    onPressAndHold: qrFileDialog.open()
                }
            }
        }
    }

    function onPageCompleted() {
        console.log("Receive page loaded");
        table.model = currentWallet.subaddressModel;

        if (appWindow.currentWallet) {
          current_address = appWindow.currentWallet.address(appWindow.currentWallet.currentSubaddressAccount, 0)
              appWindow.currentWallet.subaddress.refresh(appWindow.currentWallet.currentSubaddressAccount)
              table.currentIndex = 0
        }

    }
}
