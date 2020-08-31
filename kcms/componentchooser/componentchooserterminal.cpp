/***************************************************************************
 *   Copyright (C) 2002 Joseph Wenninger <jowenn@kde.org>                  *
 *   Copyright (C) 2020 Méven Car <meven.car@kdemail.net>                  *
 *   Copyright (C) 2020 Tobias Fella <fella@posteo.de>                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA          *
 ***************************************************************************/

#include "componentchooserterminal.h"

#include <QDBusConnection>
#include <QDBusMessage>

#include <KApplicationTrader>
#include <KQuickAddons/ConfigModule>

#include "terminal_settings.h"

ComponentChooserTerminal::ComponentChooserTerminal(QObject *parent)
    : ComponentChooser(parent, QLatin1String(""), QStringLiteral("TerminalEmulator"), QStringLiteral("org.kde.konsole.desktop"))
{
}

void ComponentChooserTerminal::load()
{
    m_applications.clear();
    static_cast<KQuickAddons::ConfigModule *>(parent())->setNeedsSave(false);

    bool preferredServiceAdded = false;

    TerminalSettings settings;

    QString preferredService = settings.terminalApplication();

    KApplicationTrader::query([&preferredServiceAdded, preferredService, this](const KService::Ptr &service) {
        if (service->exec().isEmpty() || !service->categories().contains(m_type)) {
            return false;
        }
        QVariantMap application;
        application["name"] = service->name();
        application["icon"] = service->icon();
        application["storageId"] = service->storageId();
        m_applications += application;
        if ((!preferredService.isEmpty() && preferredService == service->name())) {
            m_index = m_applications.length() - 1;
            preferredServiceAdded = true;
        }
        if (service->storageId() == m_defaultApplication) {
            m_defaultIndex = m_applications.length() - 1;
        }
        return false;
    });
    if (!preferredService.isEmpty() && !preferredServiceAdded) {
        // standard application was specified by the user
        QVariantMap application;
        application["name"] = preferredService;
        application["icon"] = QStringLiteral("application-x-shellscript");
        application["storageId"] = preferredService;
        m_applications += application;
        m_index = m_applications.length() - 1;
    }
    QVariantMap application;
    application["name"] = QStringLiteral("Other...");
    application["icon"] = QStringLiteral("application-x-shellscript");
    application["storageId"] = QLatin1String("");
    m_applications += application;
    if (m_index == -1)
        m_index = 0;

    Q_EMIT applicationsChanged();
    Q_EMIT indexChanged();
    m_previousApplication = m_applications[m_index].toMap()["storageId"].toString();
}

void ComponentChooserTerminal::save()
{
    const QString storageId = m_applications[m_index].toMap()["name"].toString();

    TerminalSettings terminalSettings;
    terminalSettings.setTerminalApplication(storageId);
    terminalSettings.save();

    QDBusMessage message = QDBusMessage::createMethodCall(QStringLiteral("org.kde.klauncher5"), QStringLiteral("/KLauncher"), QStringLiteral("org.kde.KLauncher"), QStringLiteral("reparseConfiguration"));
    QDBusConnection::sessionBus().send(message);
}
