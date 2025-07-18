import { Header } from "@/components/header";
import { NavigationBar } from "@/components/navigation-bar";
import { SidenavDesktop } from "@/components/sidenav/sidenav-desktop";


export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <div className="flex flex-col min-h-viewportStable max-h-viewportStable min-w-full bg-[url('/aptos_markets_bg_light.jpg')] lg:dark:bg-[url('/aptos_markets_bg_dark.jpg')] dark:bg-[url('/bg-dark-mobile.jpg')] bg-no-repeat bg-cover bg-top">
            <SidenavDesktop />
            <div className="flex flex-col sm:pl-14 min-h-viewportStable max-h-viewportStable">
                <Header />
                <main className="grow overflow-y-auto sm:pb-9">{children}</main>
                <div className="sm:hidden block">
                    <NavigationBar />
                </div>
            </div>
        </div>
    );
}
