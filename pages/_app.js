/* pages/_app.js */
import 'bootstrap/dist/css/bootstrap.css'
// import "../styles/style.css";
import "../styles/globals.css";
import Link from "next/link";
import { useEffect } from "react";
// import Footer from "./api/footer";

function Marketplace({ Component, pageProps }) {
  useEffect(() => {
    import("bootstrap/dist/js/bootstrap");
  }, []);
  return (
    <div>
      <nav className="border-b p-6 bg-black">
        <p className="text-4xl font-bold text-white text-center">
        DopeWolves NFT
        </p>
        <div className="flex mt-4">
          <Link href="/">
            <a className="mr-4 text-gray-50 hover:text-pink-500">Hunting Season</a>
          </Link>

          <Link href="/mint">
            <a className="mr-6 text-gray-50 hover:text-pink-500">
              Mint DopeWolves
            </a>
          </Link>
        </div>
      </nav>
      <br />

      <Component {...pageProps} />
      {/* <Footer /> */}
    </div>
  );
}

export default Marketplace;
